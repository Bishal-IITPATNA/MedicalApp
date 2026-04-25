"""
Idempotent seeder for the 5 default Seevak Care accounts.

Importable (`from seed_default_users import seed`) so that the Flask app
factory can call it on first boot when SEED_DEFAULT_USERS=true.

Also runnable directly:
    python seed_default_users.py
"""

import sys
from pathlib import Path
from dotenv import load_dotenv

ROOT_DIR = Path(__file__).parent
sys.path.insert(0, str(ROOT_DIR))
load_dotenv(ROOT_DIR / ".env")

from app import db  # noqa: E402
from app.models.user import (  # noqa: E402
    User, Patient, Doctor, MedicalStore, LabStore, Admin,
)


DEFAULT_USERS = [
    {
        "email": "admin@medical.com",
        "password": "password123",
        "role": "admin",
        "profile_model": Admin,
        "profile_kwargs": {"name": "System Admin", "phone": "9000000001"},
    },
    {
        "email": "testpatient2@medical.com",
        "password": "password123",
        "role": "patient",
        "profile_model": Patient,
        "profile_kwargs": {
            "name": "Test Patient",
            "phone": "9000000002",
            "city": "Patna",
            "state": "Bihar",
            "pincode": "800001",
            "gender": "male",
            "blood_group": "O+",
        },
    },
    {
        "email": "testdoctor1@medical.com",
        "password": "password123",
        "role": "doctor",
        "profile_model": Doctor,
        "profile_kwargs": {
            "name": "Dr. Test Doctor",
            "phone": "9000000003",
            "specialty": "General Medicine",
            "qualification": "MBBS, MD",
            "experience_years": 10,
            "consultation_fee": 500.0,
            "city": "Patna",
            "state": "Bihar",
            "pincode": "800001",
        },
    },
    {
        "email": "testmedical@store.com",
        "password": "password123",
        "role": "medical_store",
        "profile_model": MedicalStore,
        "profile_kwargs": {
            "name": "Test Medical Store",
            "phone": "9000000004",
            "license_number": "ML-001",
            "city": "Patna",
            "state": "Bihar",
            "pincode": "800001",
        },
    },
    {
        "email": "pathlab@example.com",
        "password": "password123",
        "role": "lab_store",
        "profile_model": LabStore,
        "profile_kwargs": {
            "name": "Path Lab",
            "phone": "9000000005",
            "license_number": "LL-001",
            "city": "Patna",
            "state": "Bihar",
            "pincode": "800001",
        },
    },
]


def _upsert(spec: dict) -> None:
    user = User.query.filter_by(email=spec["email"]).first()
    if user is None:
        user = User(email=spec["email"], role=spec["role"], is_active=True)
        user.set_password(spec["password"])
        db.session.add(user)
        db.session.flush()
    else:
        user.set_password(spec["password"])
        user.role = spec["role"]
        user.is_active = True

    profile_model = spec["profile_model"]
    existing = profile_model.query.filter_by(user_id=user.id).first()
    if existing is None:
        db.session.add(profile_model(user_id=user.id, **spec["profile_kwargs"]))
    else:
        for k, v in spec["profile_kwargs"].items():
            setattr(existing, k, v)


def seed() -> None:
    """Idempotent — safe to call on every boot."""
    for spec in DEFAULT_USERS:
        _upsert(spec)
    db.session.commit()


if __name__ == "__main__":
    from app import create_app
    app = create_app()
    with app.app_context():
        db.create_all()
        seed()
        print("Seeded default users.")
