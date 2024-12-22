from setuptools import setup, find_packages

setup(
    name="adv_backend",
    version="0.1",
    packages=find_packages(),
    install_requires=[
        "fastapi",
        "uvicorn",
        "python-dotenv",
        "openai",
        "pydantic"
    ]
)