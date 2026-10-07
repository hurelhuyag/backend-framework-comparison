"""Test runner that uses the configured database as-is.

The demo's tables are unmanaged and already hold the dataset (test.sh hands every run a fresh
clone of demo_template), so there is nothing to create or migrate. Django's default runner would
create an empty test_<NAME> database and run the contrib migrations into it; this runner skips
database setup and teardown entirely. Each TestCase still runs inside a transaction that is rolled
back afterwards, so tests leave the database unchanged.
"""

from django.test.runner import DiscoverRunner


class ExistingDatabaseRunner(DiscoverRunner):
    def setup_databases(self, **kwargs):
        return None

    def teardown_databases(self, old_config, **kwargs):
        pass
