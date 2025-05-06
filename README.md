# At a Glance v4 - Film Production Calendar Scheduler

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) A web application built with Flask and Docker to generate, view, and manage film production scheduling calendars. This tool provides a clear "at a glance" overview of prep, shoot, and wrap periods, incorporating holidays, hiatuses, weekends, and specific daily production details.

## Key Features

* **Project Management:** Create and manage multiple film projects with defined prep, shoot, and wrap dates.
* **Automatic Calendar Generation:** Generates a full production calendar based on project dates, automatically calculating shoot days.
* **Customizable Dates:** Handles weekends (marking them non-working by default), working weekends, bank holidays (per project), hiatus periods, and other special non-working/working dates.
* **Detailed Day Editing (Admin):**
    * Assign Main Unit details, Sequence information, Locations.
    * Track Extras and Featured Extras counts.
    * Tag days with relevant Departments (e.g., SFX, Stunts, Crane).
    * Add daily notes.
* **Viewer Mode:** Secure, read-only view of the generated calendar accessible via a viewer password.
* **Admin Mode:** Secure administration backend (separate password) for managing:
    * Projects (Create, Edit, Delete)
    * Calendar Days (Edit details)
    * Global Locations & Location Areas (with color-coding)
    * Global Departments
    * Project-specific special dates (Holidays, Hiatuses, Working Weekends)
* **Data Visualization:** Displays counters for department usage and location usage within the calendar view.
* **API Backend:** Includes a basic API for managing projects, calendars, locations, departments, etc. (primarily used by admin frontend).
* **Dockerized:** Easy setup and deployment using Docker and Docker Compose.

## Tech Stack

* **Backend:** Python 3.11, Flask
* **WSGI Server:** Gunicorn
* **Data Storage:** JSON files
* **Frontend:** HTML, CSS, JavaScript (Vanilla JS)
* **Containerization:** Docker, Docker Compose

## Project Structure

    .
    ├── Dockerfile             # Defines the Docker image
    ├── docker-compose.yml     # Defines the Docker services
    ├── requirements.txt       # Python dependencies
    ├── .env.example           # Example environment variables
    ├── app.py                 # Main Flask application factory and entry point
    ├── routes/                # Flask Blueprints for different sections
    │   ├── admin.py
    │   ├── api.py
    │   ├── auth.py
    │   └── main.py
    ├── utils/                 # Helper modules and core logic
    │   ├── calendar_generator.py # Logic for creating calendar days
    │   ├── decorators.py      # Access control decorators (@admin_required, etc.)
    │   ├── helpers.py         # Data loading/saving, other core functions
    │   └── ...                # Other utility modules (dates, files)
    ├── templates/             # HTML templates (Jinja2)
    │   ├── admin/             # Admin-specific templates
    │   └── ...
    ├── static/                # Static assets (CSS, JS, Images)
    │   ├── css/
    │   ├── js/
    │   └── ...
    ├── data/                  # Application data (SHOULD BE BACKED UP)
    │   ├── projects/          # Data for each project (in subfolders)
    │   │   └── {project_uuid}/
    │   │       ├── main.json
    │   │       ├── calendar.json
    │   │       └── ... (holidays.json, hiatus.json etc.)
    │   ├── areas.json         # Global location areas
    │   ├── departments.json   # Global departments
    │   └── locations.json     # Global locations
    ├── logs/                  # Application logs
    └── README.md              # This file

## Setup and Installation

### Prerequisites

* Docker ([Install Docker](https://docs.docker.com/engine/install/))
* Docker Compose ([Install Docker Compose](https://docs.docker.com/compose/install/))

### Steps

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/daire84/at-a-glance-v4.git](https://github.com/daire84/at-a-glance-v4.git)
    cd at-a-glance-v4
    ```

2.  **Configure Environment Variables:**
    * Copy the example environment file:
        ```bash
        cp .env.example .env
        ```
    * Edit the `.env` file with your preferred settings:
        * `SECRET_KEY`: **Required.** A long, random string for Flask session security. Generate one using `python -c 'import secrets; print(secrets.token_hex(16))'`.
        * `ADMIN_PASSWORD`: **Required.** The password for accessing the admin section.
        * `VIEWER_PASSWORD`: **Required.** The password for accessing the read-only viewer mode.
        * `FLASK_DEBUG`: Set to `True` for development mode (enables debugger, auto-reload), `False` for production. Defaults to `False`.

3.  **Build and Run with Docker Compose:**
    * From the project root directory (`at-a-glance-v4`), run:
        ```bash
        docker-compose up --build -d
        ```
        * `--build`: Forces Docker to build the image based on the `Dockerfile`.
        * `-d`: Runs the containers in detached mode (in the background).

4.  **Access the Application:**
    * Open your web browser and navigate to `http://localhost:5000` (or the host/port configured in `docker-compose.yml` if you changed it).

## Usage

* **Viewer Mode:** Navigate to the root URL (`/`). You will be prompted for the Viewer Password defined in your `.env` file. After login, you can select a project to view its calendar.
* **Admin Mode:**
    * Navigate to `/admin/login`.
    * Enter the Admin Password defined in your `.env` file.
    * Upon successful login, you will be redirected to the Admin Dashboard (`/admin`).
    * From the dashboard, you can:
        * Create new projects or select existing ones to edit.
        * Manage global settings like Locations, Areas, and Departments via dedicated pages.
        * Manage project-specific special dates (Holidays, Hiatuses, etc.).
        * Edit individual days on the project calendar view.

## Data Storage

This application currently stores all its data as JSON files within the `data/` directory inside the container volume.

* Global configurations (locations, departments, areas) are stored directly in `data/`.
* Each project's data (main details, calendar, holidays, etc.) is stored in a separate subdirectory under `data/projects/`, named with a unique UUID.

**Important:** Ensure the volume mapped to `/app/data` in your `docker-compose.yml` is persistent and regularly backed up, as this contains all user-generated data.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue. (Optional: Add more specific contribution guidelines if desired).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. (Optional: Create a LICENSE file with the MIT license text or choose another license).
