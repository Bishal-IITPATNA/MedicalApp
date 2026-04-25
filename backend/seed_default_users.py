"""
Idempotent seed script for the 5 default users described in README.md.
Run with:
    cd /app/backend && /root/.venv/bin/python seed_default_users.py
"""

import sys
from pathlib import Path
from dotenv import load_dotenv

ROOT_DIR = Path(__file__).parent
sys.path.insert(0, str(ROOT_DIR))
load_dotenv(ROOT_DIR / ".env")

from app import create_app, db  # noqa: E402
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


def upsert_user(spec: dict) -> None:
    user = User.query.filter_by(email=spec["email"]).first()
    if user is None:
        user = User(email=spec["email"], role=spec["role"], is_active=True)
        user.set_password(spec["password"])
        db.session.add(user)
        db.session.flush()
        print(f"  + Created user: {spec['email']} ({spec['role']})")
    else:
        # Update password to ensure deterministic credentials
        user.set_password(spec["password"])
        user.role = spec["role"]
        user.is_active = True
        print(f"  ~ Updated user: {spec['email']} ({spec['role']})")

    profile_model = spec["profile_model"]
    existing_profile = profile_model.query.filter_by(user_id=user.id).first()
    if existing_profile is None:
        profile = profile_model(user_id=user.id, **spec["profile_kwargs"])
        db.session.add(profile)
        print(f"      profile created: {profile_model.__name__}")
    else:
        for k, v in spec["profile_kwargs"].items():
            setattr(existing_profile, k, v)
        print(f"      profile updated: {profile_model.__name__}")


def main() -> None:
    app = create_app()
    with app.app_context():
        db.create_all()
        print("Seeding default users...")
        for spec in DEFAULT_USERS:
            upsert_user(spec)
        db.session.commit()
        print("Done.")


if __name__ == "__main__":
    main()
