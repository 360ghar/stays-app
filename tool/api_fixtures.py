"""Write backend-shaped API fixtures for the stays app's contract tests.

Each response fixture is built by validating sample data through the backend's own Pydantic
response model and dumping it the way FastAPI does (`mode="json"`, `by_alias=True`). The output
therefore carries every field, default and alias the backend really sends. Every DTO the app parses
has a fixture here. Request fixtures are the flattened JSON schemas of the bodies the app sends.
Operation fixtures come from `360ghar-backend/docs/openapi.json`.

Run from the app root with the backend environment:

    uv run --project "$GHAR_BACKEND_DIR" \
        python tool/api_fixtures.py

It imports schemas only: no app start-up, no database, no network. `tool/gen_enums.py` writes
`enums.json` next to these files.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any

APP = Path(__file__).resolve().parents[1]
# `GHAR_BACKEND_DIR` points at another backend checkout (CI).
BACKEND = Path(
    os.environ.get("GHAR_BACKEND_DIR")
    or APP.parents[2] / "github" / "360ghar" / "360ghar-backend"
)
OUT = APP / "test" / "fixtures" / "api"
sys.path.insert(0, str(BACKEND))

from app.api.api_v1.endpoints.auth import (  # noqa: E402
    DeleteAccountRequest,
    IdentifierStatusRequest,
    IdentifierStatusResponse,
    LastMethodRequest,
)
from app.api.api_v1.endpoints.notifications import (  # noqa: E402
    DeviceRegisterIn,
    DeviceRegistration,
    DeviceUnregisterIn,
)
from app.infrastructure.errors import (  # noqa: E402
    ErrorEnvelope,
    ValidationErrorEnvelope,
    error_body,
    validation_details,
)
from app.schemas.booking import (  # noqa: E402
    Booking,
    BookingAvailability,
    BookingCancel,
    BookingCreate,
    BookingOccupancyCheck,
    BookingOccupancyResult,
    BookingPricing,
    BookingReview,
)
from app.schemas.common import (  # noqa: E402
    NotificationSettings,
    NotificationSettingsWrite,
    PrivacySettings,
    PrivacySettingsPatch,
)
from app.schemas.core import BugReportCreate, BugReportResponse  # noqa: E402
from app.schemas.pagination import CursorPage  # noqa: E402
from app.schemas.property import Property, PropertyDetail  # noqa: E402
from app.schemas.stays_chat import BookingMessageCreate, BookingMessageOut  # noqa: E402
from app.schemas.swipe import (  # noqa: E402
    BatchRemoveRequest,
    BatchRemoveResult,
    SwipeCreate,
    SwipeOut,
)
from app.schemas.user import (  # noqa: E402
    AuthGateState,
    LocationUpdate,
    SelfUser,
    UserLocation,
    UserPreferences,
    UserPreferencesPatch,
    UserUpdate,
)

NOW = "2026-09-30T10:15:02Z"
COMPANY_NUMBER = "+911800000360"


def dump(model_cls, data):
    return model_cls.model_validate(data).model_dump(mode="json", by_alias=True)


def page(model_cls, items, *, next_cursor=None, limit=20, total=None):
    return dump(
        CursorPage[model_cls],
        {
            "items": items,
            "next_cursor": next_cursor,
            "has_more": next_cursor is not None,
            "limit": limit,
            "total": total,
        },
    )


def image(pid: int, slot: int, category: str, *, main: bool = False):
    return {
        "id": pid * 10 + slot,
        "property_id": pid,
        "image_url": f"https://cdn.example.com/p{pid}/{category}-{slot}.jpg",
        "image_category": category,
        "display_order": slot,
        "is_main_image": main,
    }


def stay(pid: int, **extra):
    """A short-stay property as the list routes send it. The owner number is already masked."""
    base = {
        "id": pid,
        "owner_id": 7,
        "title": f"Sea View Villa {pid}",
        "description": "Two bedrooms and a terrace on the beach.",
        "property_type": "villa",
        "purpose": "short_stay",
        "base_price": 0,
        "daily_rate": 3_500,
        "area_sqft": 1450,
        "status": "available",
        "is_available": True,
        "available_from": "2026-11-01",
        "view_count": 12,
        "like_count": 3,
        "interest_count": 1,
        "created_at": NOW,
        "updated_at": NOW,
        "city": "Goa",
        "country": "India",
        "locality": "Candolim",
        "latitude": 15.5189,
        "longitude": 73.7619,
        "bedrooms": 2,
        "bathrooms": 2,
        "max_occupancy": 4,
        "minimum_stay_days": 2,
        "main_image_url": f"https://cdn.example.com/p{pid}/main.jpg",
        "virtual_tour_url": "https://tours.example.com/t/abc",
        "owner_name": "Meera Shah",
        # Masked for a viewer who is not the owner: the agent number, else the company number.
        "owner_contact": COMPANY_NUMBER,
        "features": ["Sea view", "Private pool"],
        "images": [
            image(pid, 1, "hall", main=True),
            image(pid, 2, "kitchen"),
            image(pid, 3, "floor_plan"),
        ],
        # `id` is the amenity id, not the property_amenities row id.
        "amenities": [
            {"id": 11, "title": "Swimming Pool", "icon": "pool", "category": "recreation"},
            {"id": 12, "title": "Wi-Fi", "icon": None, "category": None},
        ],
    }
    base.update(extra)
    return base


def long_stay(pid: int, **extra):
    """A rent listing has no nightly_rate. The app must not turn monthly_rent into one."""
    fields = {
        "purpose": "rent",
        "daily_rate": None,
        "monthly_rent": 45_000,
        "security_deposit": 90_000,
        "property_type": "apartment",
    }
    return stay(pid, **{**fields, **extra})


def public_user(uid: int, name: str, avatar: str | None = None):
    return {"id": uid, "display_name": name, "avatar_url": avatar}


def booking(bid: int, **extra):
    base = {
        "id": bid,
        "user_id": 50,
        "property_id": 1,
        "booking_reference": f"BK-2026-{bid:05d}",
        "check_in_date": "2026-11-10T00:00:00Z",
        "check_out_date": "2026-11-13T00:00:00Z",
        "nights": 3,
        "guests": 2,
        "base_amount": 10_500,
        "taxes_amount": 1_260.5,
        "service_charges": 525,
        "discount_amount": 0,
        "total_amount": 12_285.5,
        "booking_status": "pending",
        "payment_status": "pending",
        "primary_guest_name": "Asha Verma",
        "primary_guest_phone": "+919800000000",
        "primary_guest_email": "asha@example.com",
        "special_requests": "Late check-in",
        "guest_details": {"adults": 2},
        "early_check_in": False,
        "late_check_out": False,
        "property": {
            "id": 1,
            "title": "Sea View Villa 1",
            "city": "Goa",
            "country": "India",
            "cover_image_url": "https://cdn.example.com/p1/main.jpg",
        },
        "guest": public_user(50, "Asha Verma", None),
        "created_at": NOW,
        "updated_at": NOW,
    }
    base.update(extra)
    return base


def self_user(**extra):
    base = {
        "id": 50,
        "supabase_user_id": "0f5e8d9a-1c2b-4d3e-8f7a-6b5c4d3e2f1a",
        "email": "asha@example.com",
        "phone": "+919800000000",
        "full_name": "Asha Verma",
        "date_of_birth": "1994-02-11",
        "role": "user",
        "is_active": True,
        "is_verified": True,
        "phone_verified": True,
        "email_verified": False,
        "last_auth_method": "phone_otp",
        "last_auth_method_at": NOW,
        "profile_image_url": "https://cdn.example.com/u/50.jpg",
        "preferences": {"purpose": "short_stay", "property_type": ["villa"], "max_distance_km": 5},
        "current_latitude": 15.51,
        "current_longitude": 73.76,
        "notification_settings": {"push_notifications": True, "promotional_emails": False},
        "privacy_settings": {"profile_visibility": "agents_only"},
        "agent_id": 4,
        "created_at": NOW,
        "updated_at": NOW,
    }
    base.update(extra)
    return base


def flatten_request(model_cls) -> dict[str, Any]:
    """The request body contract the app must satisfy: required keys, strictness, key limits."""
    schema = model_cls.model_json_schema(mode="validation")
    defs = schema.get("$defs", {})

    def resolve(node: dict[str, Any]) -> tuple[dict[str, Any], bool]:
        nullable = False
        while True:
            if "$ref" in node:
                node = defs[node["$ref"].split("/")[-1]]
            elif "anyOf" in node:
                members = [m for m in node["anyOf"] if m.get("type") != "null"]
                nullable = nullable or len(members) != len(node["anyOf"])
                node = members[0]
            else:
                return node, nullable

    properties: dict[str, Any] = {}
    for name, raw in schema.get("properties", {}).items():
        node, nullable = resolve(raw)
        info = {
            key: node[key]
            for key in ("enum", "maxLength", "minLength", "maximum", "minimum", "type", "format")
            if key in node
        }
        info["nullable"] = nullable
        if "properties" in node:
            info["properties"] = sorted(node["properties"])
        properties[name] = info
    return {
        "required": sorted(schema.get("required", [])),
        "extra_forbidden": schema.get("additionalProperties") is False,
        "properties": properties,
    }


def operations() -> dict[str, Any]:
    """Every operation in the OpenAPI document: query keys, body schema and response codes."""
    spec = json.loads((BACKEND / "docs" / "openapi.json").read_text())
    out: dict[str, Any] = {}
    for path, item in spec["paths"].items():
        for method, op in item.items():
            if method not in ("get", "post", "put", "patch", "delete"):
                continue
            query = {}
            headers = []
            for param in op.get("parameters", []):
                schema = param.get("schema", {})
                members = [m for m in schema.get("anyOf", [schema]) if m.get("type") != "null"]
                base = members[0] if members else {}
                if param["in"] == "query":
                    query[param["name"]] = {
                        key: base[key] for key in ("maximum", "minimum", "type") if key in base
                    }
                elif param["in"] == "header":
                    headers.append(param["name"])
            body = (
                op.get("requestBody", {}).get("content", {}).get("application/json", {}).get("schema")
            )
            out[f"{method.upper()} {path}"] = {
                "query": query,
                "headers": headers,
                "body": body.get("$ref", "").split("/")[-1] if body else None,
                "responses": sorted(code for code in op["responses"] if code.isdigit()),
            }
    return dict(sorted(out.items()))


def fixtures():
    next_cursor = "eyJrIjpbIjIwMjYtMDktMzAiLDJdLCJmIjoiYWJjIn0"
    return {
        "properties": {
            "list_page": page(
                Property,
                [stay(1, distance_km=2.4), stay(2, distance_km=5.1, owner_contact=None)],
                next_cursor=next_cursor,
                limit=30,
            ),
            "last_page": page(Property, [stay(3)], limit=30),
            "mixed_page": page(Property, [stay(4), long_stay(5)], limit=30),
            "detail": dump(PropertyDetail, stay(1, agent={"id": 4, "name": "Ravi Kumar",
                                                           "contact_number": "+919811111111"})),
            "recommendations": page(Property, [stay(6)], limit=10),
        },
        "swipes": {
            "history_page": page(
                Property, [stay(1, liked=True), stay(2, liked=True)], next_cursor=next_cursor
            ),
            "created": dump(SwipeOut, {"id": 301, "property_id": 1, "is_liked": True}),
            "batch_removed": dump(
                BatchRemoveResult, {"removed_count": 2, "failed_property_ids": [9]}
            ),
        },
        "bookings": {
            "list_page": page(
                Booking,
                [
                    booking(11),
                    booking(
                        12,
                        property=None,
                        guest=None,
                        booking_status="confirmed",
                        payment_status="paid",
                    ),
                ],
                next_cursor=next_cursor,
            ),
            "last_page": page(Booking, [booking(13, booking_status="cancelled")]),
            "created": dump(Booking, booking(14)),
            "pricing": dump(
                BookingPricing,
                {
                    "property_id": 1,
                    "check_in_date": "2026-11-10T00:00:00Z",
                    "check_out_date": "2026-11-13T00:00:00Z",
                    "guests": 2,
                    "nights": 3,
                    "base_amount": 10_500,
                    "taxes_amount": 1_260.5,
                    "service_charges": 525,
                    "discount_amount": 0,
                    "total_amount": 12_285.5,
                },
            ),
            "occupancy_ok": dump(
                BookingOccupancyResult, {"occupancy_ok": True, "max_occupancy": 4}
            ),
            "occupancy_full": dump(
                BookingOccupancyResult,
                {"occupancy_ok": False, "reason": "Maximum 4 guests", "max_occupancy": 4},
            ),
            "messages_page": page(
                BookingMessageOut,
                [
                    {"id": 502, "sender_id": 7, "body": "See you on the 10th.", "created_at": NOW},
                    {"id": 501, "sender_id": 50, "body": "Is early check-in possible?",
                     "created_at": "2026-09-30T09:00:00Z"},
                ],
                next_cursor=next_cursor,
                limit=30,
            ),
            "message_created": dump(
                BookingMessageOut,
                {"id": 503, "sender_id": 50, "body": "Thanks!", "created_at": NOW},
            ),
        },
        "users": {
            "profile": dump(SelfUser, self_user()),
            "profile_minimal": dump(
                SelfUser,
                self_user(
                    email=None, phone=None, full_name=None, date_of_birth=None,
                    profile_image_url=None, agent_id=None, last_auth_method=None,
                ),
            ),
            "notification_settings": dump(
                NotificationSettings, {"push_notifications": False, "promotional_emails": True}
            ),
            "privacy_settings": dump(PrivacySettings, {"profile_visibility": "private"}),
            "preferences": dump(
                UserPreferences, {"purpose": "short_stay", "budget_max": 9000.5}
            ),
            "location": dump(UserLocation, {"current_latitude": 15.51, "current_longitude": 73.76}),
        },
        "auth": {
            "identifier_status": dump(
                IdentifierStatusResponse,
                {"exists": True, "verified": True, "has_password": False, "channel": "phone",
                 "next_step": "otp"},
            ),
            "auth_state": dump(
                AuthGateState,
                {"stage": "app_onboarding", "next_action": "complete_onboarding",
                 "missing_fields": []},
            ),
        },
        "support": {
            "bug": dump(
                BugReportResponse,
                {
                    "id": 3, "user_id": 50, "source": "mobile", "bug_type": "ui_bug",
                    "severity": "low", "status": "open", "title": "Map pin overlaps",
                    "description": "On 320 px width.", "steps_to_reproduce": None,
                    "expected_behavior": None, "actual_behavior": None,
                    "device_info": {"platform": "ios"}, "app_version": "1.0.1", "media_urls": None,
                    "tags": ["stays"], "assigned_to": None, "resolution": None,
                    "resolved_at": None, "created_at": NOW, "updated_at": None,
                },
            ),
        },
        "notifications": {
            "registration": dump(
                DeviceRegistration,
                {"platform": "ios", "app_key": "stays", "app_version": "1.0.1+2",
                 "locale": "en_IN", "last_seen": NOW},
            ),
        },
        "errors": {
            "unauthorized": dump(
                ErrorEnvelope, error_body("TOKEN_INVALID", "The token is not valid.")
            ),
            "not_found": dump(
                ErrorEnvelope, error_body("PROPERTY_NOT_FOUND", "Property not found.")
            ),
            "pricing_unavailable": dump(
                ErrorEnvelope,
                error_body("PRICING_UNAVAILABLE", "This stay has no nightly rate."),
            ),
            "invalid_date_range": dump(
                ErrorEnvelope,
                error_body("INVALID_DATE_RANGE", "The stay must cover at least one night."),
            ),
            "rate_limited": dump(
                ErrorEnvelope, error_body("RATE_LIMIT_EXCEEDED", "Too many requests.")
            ),
            "server": dump(
                ErrorEnvelope, error_body("INTERNAL_ERROR", "An unexpected error occurred")
            ),
            "validation": dump(
                ValidationErrorEnvelope,
                error_body(
                    "VALIDATION_ERROR",
                    "Request validation failed",
                    validation_details(
                        [
                            {"loc": ("body", "primary_guest_email"),
                             "msg": "value is not a valid email address",
                             "type": "value_error"},
                            {"loc": ("query", "radius"),
                             "msg": "Input should be a valid integer",
                             "type": "int_parsing"},
                        ]
                    ),
                ),
            ),
            "validation_no_fields": dump(
                ValidationErrorEnvelope,
                error_body("INVALID_CURSOR", "Cursor does not match", {"fields": []}),
            ),
        },
        # Request bodies the app sends.
        "requests": {
            name: flatten_request(model)
            for name, model in {
                "BookingCreate": BookingCreate,
                "BookingAvailability": BookingAvailability,
                "BookingOccupancyCheck": BookingOccupancyCheck,
                "BookingCancel": BookingCancel,
                "BookingReview": BookingReview,
                "BookingMessageCreate": BookingMessageCreate,
                "SwipeCreate": SwipeCreate,
                "BatchRemoveRequest": BatchRemoveRequest,
                "UserUpdate": UserUpdate,
                "UserPreferencesPatch": UserPreferencesPatch,
                "NotificationSettingsWrite": NotificationSettingsWrite,
                "PrivacySettingsPatch": PrivacySettingsPatch,
                "LocationUpdate": LocationUpdate,
                "BugReportCreate": BugReportCreate,
                "DeviceRegisterIn": DeviceRegisterIn,
                "DeviceUnregisterIn": DeviceUnregisterIn,
                "DeleteAccountRequest": DeleteAccountRequest,
                "LastMethodRequest": LastMethodRequest,
                "IdentifierStatusRequest": IdentifierStatusRequest,
            }.items()
        },
        "operations": operations(),
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for group, data in fixtures().items():
        path = OUT / f"{group}.json"
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
        print(f"wrote {path.relative_to(APP)}")


if __name__ == "__main__":
    main()
