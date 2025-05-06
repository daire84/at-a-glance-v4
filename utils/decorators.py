# utils/decorators.py
from functools import wraps
from flask import session, flash, redirect, url_for, request

def viewer_required(f):
    """Decorator to require viewer or admin login."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Allow access if either viewer or admin role is set
        if 'user_role' not in session or session['user_role'] not in ['viewer', 'admin']:
            flash('Login required to view this page.', 'warning')
            # Redirect to the viewer login page defined in the 'auth' blueprint
            return redirect(url_for('auth.login', next=request.url))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """Decorator to require admin login."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('user_role') != 'admin':
            flash('Admin access required.', 'error')
             # Redirect to the admin login page defined in the 'auth' blueprint
            return redirect(url_for('auth.admin_login', next=request.url))
        return f(*args, **kwargs)
    return decorated_function