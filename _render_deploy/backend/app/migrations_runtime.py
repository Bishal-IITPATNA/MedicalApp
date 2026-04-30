"""
Lightweight, idempotent schema migrations.

This sits next to Flask-Migrate but solves a different problem: when the
deployment uses `db.create_all()` for first-boot bootstrap, that helper
won't ALTER existing tables to add new columns. The functions below run
`ALTER TABLE ... ADD COLUMN IF NOT EXISTS ...` (Postgres-safe; SQLite
gracefully ignored) so new columns appear on existing deployments
without operator intervention.

Add new entries to PENDING_COLUMNS as the schema evolves.
"""

from __future__ import annotations

import logging
from sqlalchemy import text

logger = logging.getLogger(__name__)


# (table, column_name, column_ddl) - DDL is the bit after `ADD COLUMN ...`
PENDING_COLUMNS: list[tuple[str, str, str]] = [
    # Prescription upload feature (2026-04)
    ("medicine_orders", "prescription_image",        "TEXT"),
    ("medicine_orders", "prescription_filename",     "VARCHAR(255)"),
    ("medicine_orders", "prescription_uploaded_at",  "TIMESTAMP"),
    ("lab_test_orders", "prescription_image",        "TEXT"),
    ("lab_test_orders", "prescription_filename",     "VARCHAR(255)"),
    ("lab_test_orders", "prescription_uploaded_at",  "TIMESTAMP"),
]


def run_pending_migrations(db) -> None:
    """Apply outstanding ADD COLUMN migrations idempotently."""
    dialect = db.engine.dialect.name  # 'postgresql', 'sqlite', ...
    if dialect == "postgresql":
        sql_template = (
            'ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {col} {ddl}'
        )
    elif dialect == "sqlite":
        # SQLite has no IF NOT EXISTS for ADD COLUMN; we sniff PRAGMA.
        sql_template = None
    else:
        sql_template = (
            'ALTER TABLE {table} ADD COLUMN {col} {ddl}'
        )

    with db.engine.begin() as conn:
        for table, col, ddl in PENDING_COLUMNS:
            try:
                if dialect == "sqlite":
                    info = conn.execute(text(f"PRAGMA table_info({table})")).fetchall()
                    existing = {row[1] for row in info}
                    if col in existing:
                        continue
                    conn.execute(text(f'ALTER TABLE {table} ADD COLUMN {col} {ddl}'))
                else:
                    conn.execute(text(sql_template.format(table=table, col=col, ddl=ddl)))
                logger.info("Applied migration: %s.%s", table, col)
            except Exception as exc:  # pragma: no cover
                logger.warning("Migration skipped %s.%s: %s", table, col, exc)
