from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    # Enterprise Django Admin Console
    path('admin/', admin.site.urls),

    # PMS Admin Core Management REST API endpoints
    path('api/admin/', include('apps.admin_core.urls')),
]
