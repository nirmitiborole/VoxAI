from dotenv import load_dotenv
from livekit import agents
from livekit.agents import AgentSession, Agent, JobContext, WorkerOptions
from livekit.plugins import groq, deepgram

load_dotenv()

async def entrypoint(ctx: JobContext):
    await ctx.connect()

    session = AgentSession(
        llm=groq.LLM(
            model="llama-3.3-70b-versatile",
            temperature=0.3,
        ),
        stt=deepgram.STT(
            model="nova-2-general",
        ),
        tts=deepgram.TTS(
            model="aura-arcas-en",  # Natural male voice
            encoding="linear16",
            sample_rate=24000
        )


    )

    await session.start(
        room=ctx.room,
        agent=Agent(
            instructions="You are a helpful AI assistant in a voice chatbot app. Provide friendly, concise, and helpful responses."
        )
    )

    await session.generate_reply(
        instructions="Say: Welcome to VoxAI! How can I assist you today?"
    )


if __name__ == "__main__":
    agents.cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))
