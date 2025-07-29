from .db import DatabaseSettings


class Settings(DatabaseSettings):
    project_name: str = "stock_backend"
    debug: bool = False
