@app.route('/admin/project/<project_id>', methods=['GET', 'POST'])
def admin_project(project_id):
    """Project details editor"""
    if request.method == 'POST':
        try:
            # Handle form submission
            form_data = request.form.to_dict()
            
            # Get existing project or create new
            if project_id != 'new':
                project = get_project(project_id)
                if not project:
                    flash('Project not found', 'error')
                    return redirect(url_for('admin_dashboard'))
                
                # Store original dates to check if dates are changed
                original_dates = {
                    'prepStartDate': project.get('prepStartDate'),
                    'shootStartDate': project.get('shootStartDate'),
                    'wrapDate': project.get('wrapDate')
                }
            else:
                project = {'id': str(uuid.uuid4())}
                original_dates = {}
            
            # Update project with form data
            for key, value in form_data.items():
                project[key] = value
            
            # Save project
            save_project(project)
            
            # Only generate calendar if this is a new project or if the user explicitly confirmed
            # they want to regenerate with new dates
            dates_changed = (
                project_id == 'new' or
                original_dates.get('prepStartDate') != project.get('prepStartDate') or
                original_dates.get('shootStartDate') != project.get('shootStartDate') or
                original_dates.get('wrapDate') != project.get('wrapDate')
            )
            
            if project_id == 'new':
                # For new projects, always generate the calendar
                generate_calendar(project)
                flash('Project created and calendar generated successfully', 'success')
            elif dates_changed and request.form.get('regenerate_calendar') == 'yes':
                # Only regenerate if dates changed AND user confirmed
                generate_calendar(project)
                flash('Project updated and calendar regenerated successfully', 'success')
            else:
                # Otherwise just save the project without regenerating calendar
                flash('Project updated successfully', 'success')
            
            return redirect(url_for('admin_calendar', project_id=project['id']))
            
        except Exception as e:
            logger.error(f"Error saving project: {str(e)}")
            flash(f'Error saving project: {str(e)}', 'error')
    
    # GET request or form validation failed
    project = get_project(project_id) if project_id != 'new' else {}
    return render_template('admin/project.html', project=project)
