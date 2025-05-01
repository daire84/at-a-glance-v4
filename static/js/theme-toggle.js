/**
 * Theme toggle functionality
 */
document.addEventListener('DOMContentLoaded', function() {
    // Find the theme toggle element
    const themeToggle = document.getElementById('theme-toggle');
    
    // Set initial state based on localStorage or default to dark theme
    const currentTheme = localStorage.getItem('theme') || 'dark';
    
    // Apply the theme
    applyTheme(currentTheme);
    
    // Add toggle functionality if element exists
    if (themeToggle) {
        // Update toggle to match current theme
        updateToggleUI(currentTheme);
        
        // Add event listener
        themeToggle.addEventListener('click', function() {
            // Get current theme
            const currentTheme = document.body.classList.contains('light-theme') ? 'light' : 'dark';
            
            // Toggle to other theme
            const newTheme = currentTheme === 'light' ? 'dark' : 'light';
            
            // Apply the new theme
            applyTheme(newTheme);
            
            // Update toggle UI
            updateToggleUI(newTheme);
            
            // Save preference
            localStorage.setItem('theme', newTheme);
        });
    }
});

/**
 * Apply the specified theme to the document
 * @param {string} theme - 'light' or 'dark'
 */
function applyTheme(theme) {
    if (theme === 'light') {
        document.body.classList.add('light-theme');
        
        // Set light theme specific CSS variables
        document.documentElement.style.setProperty('--page-title-color', '#333333');
        document.documentElement.style.setProperty('--text-color', '#333333');
        document.documentElement.style.setProperty('--text-light', '#555555');
        
        // Calendar row colors for light theme
        document.documentElement.style.setProperty('--weekend-color', 'color-mix(in srgb, #f0f0f0 75%, var(--row-area-color, transparent))');
        document.documentElement.style.setProperty('--prep-color', 'color-mix(in srgb, #e0ffe0 75%, var(--row-area-color, transparent))');
        document.documentElement.style.setProperty('--shoot-color', 'color-mix(in srgb, #e0f0ff 75%, var(--row-area-color, transparent))');
        document.documentElement.style.setProperty('--hiatus-color', 'color-mix(in srgb, #ffe0e0 75%, var(--row-area-color, transparent))');
        document.documentElement.style.setProperty('--holiday-color', 'color-mix(in srgb, #fff0e0 75%, var(--row-area-color, transparent))');
        document.documentElement.style.setProperty('--working-weekend-color', 'color-mix(in srgb, #e0f0e0 75%, var(--row-area-color, transparent))');
        
        // Table header colors
        document.documentElement.style.setProperty('--table-header-bg', '#546e7a');
        document.documentElement.style.setProperty('--table-header-color', 'white');
        
        // Script info section
        document.documentElement.style.setProperty('--script-info-bg', '#f8f9fa');
        document.documentElement.style.setProperty('--script-info-border', '#dee2e6');
    } else {
        document.body.classList.remove('light-theme');
        
        // Reset to dark theme CSS variables
        document.documentElement.style.setProperty('--page-title-color', 'white');
        document.documentElement.style.setProperty('--text-color', '#e0e2e7');
        document.documentElement.style.setProperty('--text-light', '#a0a4ad');
        
        // Calendar row colors for dark theme
        document.documentElement.style.setProperty('--weekend-color', 'color-mix(in srgb, #3c3c3c 75%, var(--row-area-color, var(--background-alt)))');
        document.documentElement.style.setProperty('--prep-color', 'color-mix(in srgb, #2e3e2e 75%, var(--row-area-color, var(--background-alt)))');
        document.documentElement.style.setProperty('--shoot-color', 'color-mix(in srgb, #2e3e4e 75%, var(--row-area-color, var(--background-alt)))');
        document.documentElement.style.setProperty('--hiatus-color', 'color-mix(in srgb, #4e2e2e 75%, var(--row-area-color, var(--background-alt)))');
        document.documentElement.style.setProperty('--holiday-color', 'color-mix(in srgb, #4e3e2e 75%, var(--row-area-color, var(--background-alt)))');
        document.documentElement.style.setProperty('--working-weekend-color', 'color-mix(in srgb, #2e4e2e 75%, var(--row-area-color, var(--background-alt)))');
        
        // Table header colors
        document.documentElement.style.setProperty('--table-header-bg', 'var(--primary-color)');
        document.documentElement.style.setProperty('--table-header-color', 'white');
        
        // Script info section
        document.documentElement.style.setProperty('--script-info-bg', 'var(--background-alt)');
        document.documentElement.style.setProperty('--script-info-border', 'var(--border-color)');
    }
    
    // Re-apply location area colors after theme change
    setTimeout(function() {
        if (typeof window.applyLocationAreaColors === 'function') {
            const areas = window.getLocationAreas ? window.getLocationAreas() : {};
            window.applyLocationAreaColors(areas);
        } else if (typeof applyLocationAreaColors === 'function') {
            const areas = typeof getLocationAreas === 'function' ? getLocationAreas() : {};
            applyLocationAreaColors(areas);
        }
    }, 10);
}

/**
 * Update the toggle UI to reflect the current theme
 * @param {string} theme - 'light' or 'dark'
 */
function updateToggleUI(theme) {
    const themeToggle = document.getElementById('theme-toggle');
    if (!themeToggle) return;
    
    const themeIcon = themeToggle.querySelector('.theme-icon');
    const themeText = themeToggle.querySelector('.theme-text');
    
    if (theme === 'light') {
        // Update to show dark mode option
        if (themeIcon) {
            themeIcon.innerHTML = '🌙'; // Moon icon
        }
        if (themeText) {
            themeText.textContent = 'Dark Mode';
        }
    } else {
        // Update to show light mode option
        if (themeIcon) {
            themeIcon.innerHTML = '☀️'; // Sun icon
        }
        if (themeText) {
            themeText.textContent = 'Light Mode';
        }
    }
}