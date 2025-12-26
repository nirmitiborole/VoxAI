import cv2
import numpy as np
import torch
from pathlib import Path
import sys
import os

# Add Wav2Lip to path
wav2lip_path = os.path.join(os.path.dirname(__file__), 'Wav2Lip')
sys.path.append(wav2lip_path)

from models import Wav2Lip

class AvatarService:
    def __init__(self, checkpoint_path='models/wav2lip.pth', avatar_image_path='avatar.jpg'):
        self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        print(f"🎮 Using device: {self.device}")

        # Load Wav2Lip model
        self.model = self._load_model(checkpoint_path)

        # Load avatar image
        self.avatar_frame = self._load_avatar(avatar_image_path)

    def _load_model(self, checkpoint_path):
        print("📦 Loading Wav2Lip model...")
        model = Wav2Lip()
        checkpoint = torch.load(checkpoint_path, map_location=self.device, weights_only=False)

        model.load_state_dict(checkpoint["state_dict"])
        model = model.to(self.device)
        model.eval()
        print("✅ Model loaded successfully!")
        return model

    def _load_avatar(self, image_path):
        print("🖼️ Loading avatar image...")
        img = cv2.imread(image_path)
        img = cv2.resize(img, (256, 256))
        print("✅ Avatar loaded!")
        return img

    def generate_frame(self, audio_chunk):
        """Generate a single lip-synced frame from audio"""
        with torch.no_grad():
            # Preprocess
            face = self._preprocess_image(self.avatar_frame)
            audio = self._preprocess_audio(audio_chunk)

            # Generate
            pred = self.model(face, audio)

            # Postprocess
            frame = self._postprocess_image(pred)

        return frame

    def _preprocess_image(self, img):
        img = cv2.resize(img, (96, 96))
        img = img.astype(np.float32) / 255.0
        img = np.transpose(img, (2, 0, 1))
        img = torch.FloatTensor(img).unsqueeze(0).to(self.device)
        return img

    def _preprocess_audio(self, audio_chunk):
        # Convert audio to mel spectrogram
        # Simplified for now
        mel = torch.zeros(1, 1, 80, 16).to(self.device)
        return mel

    def _postprocess_image(self, pred):
        pred = pred.squeeze(0).cpu().numpy()
        pred = np.transpose(pred, (1, 2, 0))
        pred = (pred * 255).astype(np.uint8)
        pred = cv2.resize(pred, (256, 256))
        return pred

if __name__ == "__main__":
    # Test
    service = AvatarService()
    print("✅ Avatar service initialized successfully!")
