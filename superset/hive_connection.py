from superset.db_engine_specs.hive import HiveEngineSpec
from superset.models.core import Database

def add_hive_connection():
    database = Database(
        database_name='gmall_hive',
        sqlalchemy_uri='hive://localhost:10000/gmall_ads',
        engine_spec=HiveEngineSpec,
        allow_run_async=True,
        allow_file_upload=True
    )
    return database