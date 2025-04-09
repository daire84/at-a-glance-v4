# Create a backup first
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)_fix1"
mkdir -p "${BACKUP_PATH}"
cp -r /mnt/user/appdata/film-scheduler-v4/app.py "${BACKUP_PATH}/"
echo "Backup created at ${BACKUP_PATH}"

# Create a patch file for the app.py changes
cat > /mnt/user/appdata/film-scheduler-v4/fix1-prevent-data-loss.py << 'EOF'
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
EOF

# Locate the admin_project function in app.py and replace it
LINE_START=$(grep -n "def admin_project" /mnt/user/appdata/film-scheduler-v4/app.py | cut -d: -f1)
if [ -n "$LINE_START" ]; then
    # Find the end of the function
    LINE_END=$(tail -n +$LINE_START /mnt/user/appdata/film-scheduler-v4/app.py | grep -n "^@app" | head -n 1 | cut -d: -f1)
    if [ -z "$LINE_END" ]; then
        # If no next function is found, use a large number to go to end of file
        LINE_END=10000
    else
        # Adjust to actual line number
        LINE_END=$((LINE_START + LINE_END - 1))
    fi
    
    # Replace the function
    head -n $((LINE_START-1)) /mnt/user/appdata/film-scheduler-v4/app.py > /tmp/app.py.new
    cat /mnt/user/appdata/film-scheduler-v4/fix1-prevent-data-loss.py >> /tmp/app.py.new
    tail -n +$LINE_END /mnt/user/appdata/film-scheduler-v4/app.py >> /tmp/app.py.new
    
    # Move the new file into place
    mv /tmp/app.py.new /mnt/user/appdata/film-scheduler-v4/app.py
    
    echo "Successfully updated app.py with data loss prevention"
else
    echo "Could not find admin_project function in app.py"
fi

