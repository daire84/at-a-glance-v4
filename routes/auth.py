# routes/auth.py
import os
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
# Note: We assume viewer_required/admin_required decorators stay in app.py for now
# and will be imported when needed, or applied globally if appropriate.

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Viewer login page"""
    error = None
    # Store next page if provided
    next_page = request.args.get('next')

    # If already logged in as admin, redirect to admin dashboard
    if session.get('user_role') == 'admin':
        return redirect(url_for('admin.admin_dashboard')) # Use blueprint name 'admin.'
    # If already logged in as viewer, redirect to home
    if session.get('user_role') == 'viewer':
        return redirect(url_for('main.index')) # Use blueprint name 'main.'

    if request.method == 'POST':
        # Ensure environment variable is read correctly
        viewer_password = os.environ.get('VIEWER_PASSWORD', 'viewer') # Default if not set
        if request.form['password'] == viewer_password:
            session['user_role'] = 'viewer'
            session.permanent = True # Make session persistent
            flash('You were successfully logged in', 'success')
            return redirect(next_page or url_for('main.index')) # Use blueprint name 'main.'
        else:
            error = 'Invalid password'
    # Pass next_page to template if needed for form action or links
    return render_template('login.html', error=error, next=next_page)

@auth_bp.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    """Admin login page"""
    error = None
    # Store next page if provided
    next_page = request.args.get('next')

    # If already logged in as admin, redirect to admin dashboard
    if session.get('user_role') == 'admin':
        return redirect(url_for('admin.admin_dashboard')) # Use blueprint name 'admin.'

    if request.method == 'POST':
         # Ensure environment variable is read correctly
        admin_password = os.environ.get('ADMIN_PASSWORD', 'admin') # Default if not set
        if request.form['password'] == admin_password:
            session['user_role'] = 'admin'
            session.permanent = True # Make session persistent
            flash('You were successfully logged in as admin', 'success')
            # Redirect to next_page if it exists and is safe, otherwise admin dashboard
            # Add safety check for next_page if implementing fully
            return redirect(next_page or url_for('admin.admin_dashboard')) # Use blueprint name 'admin.'
        else:
            error = 'Invalid password'
    # Pass next_page to template if needed
    return render_template('admin/login.html', error=error, next=next_page)

@auth_bp.route('/logout')
def logout():
    """Logout route"""
    session.pop('user_role', None)
    flash('You have been logged out', 'success')
    return redirect(url_for('auth.login')) # Use blueprint name 'auth.'