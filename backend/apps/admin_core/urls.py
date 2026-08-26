from django.urls import path
from .views import (
    AdminLoginView,
    StateListCreateView,
    AvailableStatesView,
    DashboardStatsView,
    OfficerListCreateView,
    OfficerDetailView,
    OfficerStatusApprovalView,
    DistrictListCreateView,
    PoliceStationListCreateView,
    CaseRecordListView,
    TransferRequestListCreateView,
    TransferRequestDetailView,
    AuditLogListView,
)

urlpatterns = [
    # Primary Authentication Endpoint
    path('login/', AdminLoginView.as_view(), name='admin-login'),

    # State Registries & Onboarding Endpoints
    path('states/', StateListCreateView.as_view(), name='admin-state-list-create'),
    path('states/available/', AvailableStatesView.as_view(), name='admin-state-available'),

    # Dashboard stats & metrics
    path('stats/', DashboardStatsView.as_view(), name='admin-dashboard-stats'),

    # Officer profile & account status management
    path('officers/', OfficerListCreateView.as_view(), name='admin-officer-list'),
    path('officers/<str:uid>/', OfficerDetailView.as_view(), name='admin-officer-detail'),
    path('officers/<str:uid>/status/', OfficerStatusApprovalView.as_view(), name='admin-officer-status-update'),

    # Districts & Police Stations
    path('districts/', DistrictListCreateView.as_view(), name='admin-district-list'),
    path('stations/', PoliceStationListCreateView.as_view(), name='admin-station-list'),

    # Case overview & metrics
    path('cases/', CaseRecordListView.as_view(), name='admin-case-list'),

    # Transfer Requests management
    path('transfers/', TransferRequestListCreateView.as_view(), name='admin-transfer-list'),
    path('transfers/<str:id>/', TransferRequestDetailView.as_view(), name='admin-transfer-detail'),

    # System Audit Logs
    path('audit-logs/', AuditLogListView.as_view(), name='admin-audit-log-list'),
]
