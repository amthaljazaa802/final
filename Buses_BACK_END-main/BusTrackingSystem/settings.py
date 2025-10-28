"""
Django settings for BusTrackingSystem project.
Production-ready configuration for Bus Tracking System with:
- SQL Server database support
- HTTPS/TLS security
- WebSocket support via Django Channels + Redis
- Environment-based secrets management
"""

from pathlib import Path
import os
from dotenv import load_dotenv

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env file
load_dotenv(BASE_DIR / '.env')

# =====================================================================
# SECURITY & ENVIRONMENT CONFIGURATION
# =====================================================================
# Load from environment variables for security
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'django-insecure-dev-key-change-in-production')
DEBUG = os.getenv('DEBUG', 'False') == 'True'

# For production, set these via environment variables:
# ALLOWED_HOSTS: comma-separated list of domain names
# Example: "api.example.com,tracking.example.com"
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

# =====================================================================
# HTTPS & SECURITY SETTINGS
# =====================================================================
# تفعيل إجباري HTTPS في الإنتاج
if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000  # 1 year
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_BROWSER_XSS_FILTER = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_CONTENT_SECURITY_POLICY = {
        'default-src': ("'self'",),
    }

# CORS & CSRF Configuration
# قائمة النطاقات المسموح بها للاتصال
CSRF_TRUSTED_ORIGINS = os.getenv(
    'CSRF_TRUSTED_ORIGINS',
    'https://localhost:3000,https://localhost:8000'
).split(',')

# CORS: قائمة أصول مسموح بها (مثل تطبيقات الجوال)
# تحذير: لا تستخدم CORS_ALLOW_ALL_ORIGINS في production!
CORS_ALLOWED_ORIGINS = os.getenv(
    'CORS_ALLOWED_ORIGINS',
    'https://localhost:3000,https://localhost:8000'
).split(',')
CORS_ALLOW_CREDENTIALS = True

# Application definition

INSTALLED_APPS = [
    'daphne',  # ASGI server for production WebSockets
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'bus_tracking',
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    'channels',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware', 
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'BusTrackingSystem.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'BusTrackingSystem.wsgi.application'
ASGI_APPLICATION = 'BusTrackingSystem.asgi.application'

# =====================================================================
# DATABASE CONFIGURATION - SQL Server
# =====================================================================

DB_ENGINE = os.getenv('DB_ENGINE', 'sqlite')  # Default to SQLite for dev
DB_NAME = os.getenv('DB_NAME', 'BusTrackingDB')
DB_HOST = os.getenv('DB_HOST', r'localhost\SQLEXPRESS')
DB_USER = os.getenv('DB_USER', '')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')

if DB_ENGINE == 'mssql':
    # SQL Server Configuration
    DATABASES = {
        'default': {
            'ENGINE': 'mssql',
            'NAME': DB_NAME,
            'HOST': DB_HOST,
            'USER': DB_USER,
            'PASSWORD': DB_PASSWORD,
            'OPTIONS': {
                'driver': 'ODBC Driver 17 for SQL Server',
                'trusted_connection': 'yes' if not DB_USER else 'no',
                'Encrypt': 'yes',  # فرض تشفير الاتصال
                'TrustServerCertificate': 'no',
                'Connection Timeout': 30,
            },
        }
    }
else:
    # SQLite for Development (يمكن استخدامه للاختبار السريع)
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# Password validation
# https://docs.djangoproject.com/en/5.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
# https://docs.djangoproject.com/en/5.2/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True

# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.2/howto/static-files/

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# تأكد من وجود المجلد static
if Path(BASE_DIR / "static").exists():
    STATICFILES_DIRS = [
        BASE_DIR / "static",
    ]
else:
    # إذا لم يكن المجلد موجوداً، أنشئ قائمة فارغة
    STATICFILES_DIRS = []

# Default primary key field type
# https://docs.djangoproject.com/en/5.2/ref/settings/#default-auto-field
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# =====================================================================
# REST FRAMEWORK CONFIGURATION (للـ Driver app API)
# =====================================================================
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour'
    }
}

# =====================================================================
# CHANNELS CONFIGURATION (للـ User app WebSocket - wss://)
# =====================================================================
# Django Channels + Redis for WebSocket support
# wss:// تشفير TLS للاتصالات الحقيقية (secure WebSocket)

# Redis Configuration for Channel Layers (production-ready)
# متغير البيئة: REDIS_URL
# مثال: redis://:password@localhost:6379/0
REDIS_URL = os.getenv('REDIS_URL', 'redis://localhost:6379/0')

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [REDIS_URL],
            'capacity': 1500,
            'expiry': 10,
        },
    },
}

# =====================================================================
# LOGGING CONFIGURATION (للـ Production)
# =====================================================================
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'file': {
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'django.log',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': os.getenv('LOG_LEVEL', 'INFO'),
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': os.getenv('LOG_LEVEL', 'INFO'),
            'propagate': False,
        },
        'bus_tracking': {
            'handlers': ['console', 'file'],
            'level': os.getenv('LOG_LEVEL', 'DEBUG'),
            'propagate': False,
        },
    },
}

# إنشاء مجلد logs إذا لم يكن موجوداً
import os as os_module
logs_dir = BASE_DIR / 'logs'
if not os_module.path.exists(logs_dir):
    os_module.makedirs(logs_dir, exist_ok=True)