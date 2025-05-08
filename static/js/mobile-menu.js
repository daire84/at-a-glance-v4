/**
 * Mobile Menu Functionality
 * Handles the mobile menu toggle button and related interactions
 */

document.addEventListener('DOMContentLoaded', function() {
    console.log("Initializing mobile menu...");
    
    // Get elements
    const menuToggle = document.getElementById('mobile-menu-toggle');
    const mainNav = document.getElementById('main-nav');
    
    if (!menuToggle || !mainNav) {
        console.warn("Mobile menu elements not found:", {
            menuToggle: !!menuToggle,
            mainNav: !!mainNav
        });
        return;
    }
    
    console.log("Mobile menu elements found");
    
    // Add click event listener to toggle button
    menuToggle.addEventListener('click', function(event) {
        // Prevent default behavior and event bubbling
        event.preventDefault();
        event.stopPropagation();
        
        // Toggle the active class on main navigation
        mainNav.classList.toggle('active');
        
        // Toggle aria-expanded attribute for accessibility
        const isExpanded = mainNav.classList.contains('active');
        menuToggle.setAttribute('aria-expanded', isExpanded ? 'true' : 'false');
        
        console.log("Menu toggled:", isExpanded ? "open" : "closed");
    });
    
    // Add click event listener to document to close menu when clicking outside
    document.addEventListener('click', function(event) {
        if (!mainNav.classList.contains('active')) {
            return; // Don't do anything if menu is already closed
        }
        
        // Check if click is outside menu and toggle button
        const clickedOnMenu = mainNav.contains(event.target);
        const clickedOnToggle = menuToggle.contains(event.target);
        
        if (!clickedOnMenu && !clickedOnToggle) {
            mainNav.classList.remove('active');
            menuToggle.setAttribute('aria-expanded', 'false');
            console.log("Menu closed via outside click");
        }
    });
    
    // Ensure menu toggle is visible on mobile only
    function updateMenuVisibility() {
        // Check if we're in mobile view
        const isMobileView = window.innerWidth <= 768;
        
        // Ensure toggle button is only visible on mobile
        menuToggle.style.display = isMobileView ? 'block' : 'none';
        
        // Reset menu state when switching to desktop view
        if (!isMobileView && mainNav.classList.contains('active')) {
            mainNav.classList.remove('active');
            menuToggle.setAttribute('aria-expanded', 'false');
        }
    }
    
    // Update on page load and resize
    updateMenuVisibility();
    window.addEventListener('resize', updateMenuVisibility);
    
    console.log("Mobile menu initialization complete");
});
