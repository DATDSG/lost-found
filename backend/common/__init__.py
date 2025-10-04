"""Common shared internal package for backend services.
Add shared utilities (db session helpers, config loaders, reusable exceptions, logging setup) here.
"""
from importlib import metadata as _md

__all__ = ["get_version"]

def get_version() -> str:
    try:
        return _md.version("lost-found-common")  # if later packaged
    except _md.PackageNotFoundError:  # pragma: no cover
        return "0.0.0-dev"
