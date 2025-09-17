# Property Search Filtering & Pagination

This guide documents how the app now performs end-to-end server-driven filtering and pagination for both `/api/v1/properties/` and `/api/v1/swipes/`.

## Backend Query Handling (FastAPI Example)

```python
from fastapi import APIRouter, Depends, Query
from app.schemas.property import UnifiedPropertyFilter
from app.services.property import get_unified_properties_optimized

router = APIRouter()

@router.get("/api/v1/properties/")
async def list_properties(
    filter_params: UnifiedPropertyFilter = Depends(),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    results = await get_unified_properties_optimized(
        filters=filter_params,
        page=page,
        limit=limit,
    )
    return {
        "properties": results.items,
        "total": results.total,
        "page": page,
        "limit": limit,
        "total_pages": results.total_pages,
        "filters_applied": filter_params.dict(exclude_none=True),
    }
```

The same pattern applies to `/api/v1/swipes/`; the service layer receives a `UnifiedPropertyFilter`, applies the filter criteria in SQL, and returns paginated results.

## Flutter/Dio Request Example

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://api.360ghar.com'));
final response = await dio.get(
  '/api/v1/properties/',
  queryParameters: {
    'city': 'Mumbai',
    'price_min': 10000,
    'price_max': 50000,
    'bedrooms_min': 2,
    'lat': 19.0760,
    'lng': 72.8777,
    'radius': 10,
    'sort_by': 'price_low',
    'page': 2,
    'limit': 20,
  },
);

final data = response.data as Map<String, dynamic>;
final properties = data['properties'] as List;
final total = data['total'];
final currentPage = data['page'];
final totalPages = data['total_pages'];
```

## React Fetch Example

```tsx
const query = new URLSearchParams({
  city: 'Pune',
  price_min: '15000',
  price_max: '45000',
  bedrooms_min: '1',
  page: '1',
  limit: '12',
});

const res = await fetch(`/api/v1/swipes/?${query.toString()}`, {
  headers: { Authorization: `Bearer ${token}` },
});
const json = await res.json();

setState({
  items: json.properties,
  total: json.total,
  page: json.page,
  limit: json.limit,
  totalPages: json.total_pages,
});
```

## Frontend Pagination Usage

- `ListingController` now forwards all active filters and pagination parameters to `/api/v1/properties/`.
- `SearchResultsView` reads the returned metadata (`total`, `page`, `limit`, `total_pages`) to render the summary and drive the next/previous controls.
- `WishlistController` sends filters to `/api/v1/swipes/` and tracks the same metadata for server-authoritative paging.
- Changing the page automatically scrolls the list back to the top so the new results start in view.
