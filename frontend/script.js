// Global variables
let specialDaysData = [];
let currentDate = new Date();
let currentMonth = currentDate.getMonth();
let currentYear = currentDate.getFullYear();
let selectedCategory = 'all';
let filteredDays = [];

// DOM Elements
const calendarGrid = document.getElementById('calendarGrid');
const currentMonthYear = document.getElementById('currentMonthYear');
const prevMonthBtn = document.getElementById('prevMonth');
const nextMonthBtn = document.getElementById('nextMonth');
const todayBtn = document.getElementById('todayBtn');
const themeToggle = document.getElementById('themeToggle');
const searchInput = document.getElementById('searchInput');
const dayDetails = document.getElementById('dayDetails');
const closeDetailsBtn = document.getElementById('closeDetails');

// Today's highlight elements
const todayDateEl = document.getElementById('todayDate');
const todayNameEl = document.getElementById('todayName');
const todayDescriptionEl = document.getElementById('todayDescription');
const todayCategoryEl = document.getElementById('todayCategory');
const todayIconEl = document.getElementById('todayIcon');
const todaySpecialEl = document.getElementById('todaySpecial');
const totalDaysEl = document.getElementById('totalDays');
const currentMonthEl = document.getElementById('currentMonth');

// Day detail elements
const detailDateEl = document.getElementById('detailDate');
const detailDayEl = document.getElementById('detailDay');
const detailNameEl = document.getElementById('detailName');
const detailDescriptionEl = document.getElementById('detailDescription');
const detailCategoryEl = document.getElementById('detailCategory');
const detailThemeEl = document.getElementById('detailTheme');
const detailIconEl = document.getElementById('detailIcon');

// Animation mapping for themes
const animationThemes = {
    'fireworks': 'Fireworks Celebration',
    'science': 'Science Lab',
    'hearts': 'Hearts & Love',
    'animals': 'Animals & Nature',
    'art': 'Art & Creativity',
    'music': 'Music & Dance',
    'space': 'Space Exploration',
    'food': 'Food & Cooking',
    'peace': 'Peace & Harmony',
    'default': 'Standard Theme'
};

// Color mapping for categories
const categoryColors = {
    'holidays': '#FF9800',
    'science-tech': '#2196F3',
    'health': '#00BCD4',
    'arts-culture': '#9C27B0',
    'animals': '#4CAF50',
    'food': '#FF6B6B',
    'relationships': '#E91E63',
    'nature': '#4CAF50',
    'other': '#6a11cb'
};

// Initialize the application
async function initApp() {
    await fetchSpecialDays();
    updateStats();
    updateTodayHighlight();
    renderCalendar();
    setupEventListeners();
}

// Fetch special days from server
async function fetchSpecialDays() {
    try {
        const response = await fetch('/api/special-days');
        specialDaysData = await response.json();
        updateStats();
        updateTodayHighlight();
        renderCalendar();
    } catch (error) {
        console.error('Error fetching special days:', error);
        todaySpecialEl.textContent = 'Error loading data';
    }
}

// Update statistics
function updateStats() {
    totalDaysEl.textContent = specialDaysData.length;
    
    const monthNames = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"];
    currentMonthEl.textContent = monthNames[currentMonth];
    
    // Update today's special
    const today = new Date();
    const todayFormatted = `${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
    const todaySpecial = specialDaysData.find(day => day.date === todayFormatted);
    todaySpecialEl.textContent = todaySpecial ? todaySpecial.day : 'No special day today';
}

// Update today's highlight
function updateTodayHighlight() {
    const today = new Date();
    const todayFormatted = `${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
    const todaySpecial = specialDaysData.find(day => day.date === todayFormatted);
    
    if (todaySpecial) {
        todayDateEl.textContent = todaySpecial.date;
        todayNameEl.textContent = todaySpecial.day;
        todayDescriptionEl.textContent = todaySpecial.description;
        todayCategoryEl.textContent = todaySpecial.category;
        todayIconEl.className = todaySpecial.icon;
        todayIconEl.style.color = todaySpecial.color;
    } else {
        todayDateEl.textContent = todayFormatted;
        todayNameEl.textContent = 'No Special Day';
        todayDescriptionEl.textContent = 'Enjoy your day!';
        todayCategoryEl.textContent = 'general';
        todayIconEl.className = 'fas fa-calendar-day';
        todayIconEl.style.color = '#6a11cb';
    }
}

// Render the calendar
function renderCalendar() {
    // Clear the calendar
    calendarGrid.innerHTML = '';
    
    // Update month/year display
    const monthNames = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"];
    currentMonthYear.textContent = `${monthNames[currentMonth]} ${currentYear}`;
    
    // Get first day of month and total days
    const firstDay = new Date(currentYear, currentMonth, 1);
    const lastDay = new Date(currentYear, currentMonth + 1, 0);
    const totalDays = lastDay.getDate();
    const firstDayIndex = firstDay.getDay(); // 0 = Sunday, 1 = Monday, etc.
    
    // Filter days based on selected category
    filteredDays = selectedCategory === 'all' 
        ? specialDaysData 
        : specialDaysData.filter(day => day.category === selectedCategory);
    
    // Create empty cells for days before the first day of the month
    for (let i = 0; i < firstDayIndex; i++) {
        const emptyDay = document.createElement('div');
        emptyDay.className = 'calendar-day empty';
        calendarGrid.appendChild(emptyDay);
    }
    
    // Create cells for each day of the month
    for (let day = 1; day <= totalDays; day++) {
        const dayElement = document.createElement('div');
        dayElement.className = 'calendar-day';
        dayElement.dataset.date = `${String(currentMonth + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        
        // Add day number
        const dayNumber = document.createElement('div');
        dayNumber.className = 'day-number';
        dayNumber.textContent = day;
        
        // Check if today
        const today = new Date();
        if (day === today.getDate() && currentMonth === today.getMonth() && currentYear === today.getFullYear()) {
            dayElement.classList.add('today');
            dayNumber.innerHTML = `${day} <i class="fas fa-star"></i>`;
        }
        
        dayElement.appendChild(dayNumber);
        
        // Add special events for this day
        const dateStr = `${String(currentMonth + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        const dayEvents = filteredDays.filter(event => event.date === dateStr);
        
        if (dayEvents.length > 0) {
            // Show up to 3 events
            dayEvents.slice(0, 3).forEach(event => {
                const eventElement = document.createElement('div');
                eventElement.className = 'day-event';
                eventElement.innerHTML = `<i class="${event.icon}"></i> ${event.day}`;
                eventElement.style.borderLeftColor = event.color;
                eventElement.style.backgroundColor = `${event.color}20`; // Add opacity
                eventElement.title = event.description;
                dayElement.appendChild(eventElement);
            });
            
            // If there are more than 3 events, show a counter
            if (dayEvents.length > 3) {
                const moreEvents = document.createElement('div');
                moreEvents.className = 'day-event';
                moreEvents.innerHTML = `<i class="fas fa-ellipsis-h"></i> +${dayEvents.length - 3} more`;
                moreEvents.style.borderLeftColor = '#6a11cb';
                dayElement.appendChild(moreEvents);
            }
            
            // Add click event to show details
            dayElement.addEventListener('click', () => showDayDetails(dateStr, dayEvents));
        } else {
            dayElement.addEventListener('click', () => {
                showDayDetails(dateStr, []);
            });
        }
        
        calendarGrid.appendChild(dayElement);
    }
}

// Show day details
function showDayDetails(dateStr, events) {
    const [month, day] = dateStr.split('-').map(Number);
    const date = new Date(currentYear, month - 1, day);
    const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    
    detailDateEl.textContent = dateStr;
    detailDayEl.textContent = dayNames[date.getDay()];
    
    if (events.length > 0) {
        const event = events[0]; // Show first event details
        detailNameEl.textContent = event.day;
        detailDescriptionEl.textContent = event.description;
        detailCategoryEl.textContent = event.category;
        detailThemeEl.textContent = animationThemes[event.animation] || 'Standard Theme';
        detailIconEl.className = event.icon;
        detailIconEl.style.color = event.color;
        
        // Apply theme to details panel
        dayDetails.style.borderLeft = `5px solid ${event.color}`;
    } else {
        detailNameEl.textContent = 'No Special Day';
        detailDescriptionEl.textContent = 'No special events scheduled for this day.';
        detailCategoryEl.textContent = 'general';
        detailThemeEl.textContent = 'Standard Theme';
        detailIconEl.className = 'fas fa-calendar-day';
        detailIconEl.style.color = '#6a11cb';
        
        // Reset theme
        dayDetails.style.borderLeft = '5px solid var(--accent-blue)';
    }
    
    // Show the details panel
    dayDetails.classList.add('active');
}

// Setup event listeners
function setupEventListeners() {
    // Month navigation
    prevMonthBtn.addEventListener('click', () => {
        currentMonth--;
        if (currentMonth < 0) {
            currentMonth = 11;
            currentYear--;
        }
        renderCalendar();
    });
    
    nextMonthBtn.addEventListener('click', () => {
        currentMonth++;
        if (currentMonth > 11) {
            currentMonth = 0;
            currentYear++;
        }
        renderCalendar();
    });
    
    // Today button
    todayBtn.addEventListener('click', () => {
        currentDate = new Date();
        currentMonth = currentDate.getMonth();
        currentYear = currentDate.getFullYear();
        renderCalendar();
        updateTodayHighlight();
    });
    
    // Theme toggle
    themeToggle.addEventListener('click', () => {
        document.body.classList.toggle('light-theme');
        const icon = themeToggle.querySelector('i');
        const text = themeToggle.querySelector('span') || themeToggle;
        
        if (document.body.classList.contains('light-theme')) {
            icon.className = 'fas fa-sun';
            themeToggle.innerHTML = '<i class="fas fa-sun"></i> Light Mode';
        } else {
            icon.className = 'fas fa-moon';
            themeToggle.innerHTML = '<i class="fas fa-moon"></i> Dark Mode';
        }
    });
    
    // Search input
    searchInput.addEventListener('input', (e) => {
        const searchTerm = e.target.value.toLowerCase();
        
        if (searchTerm.length > 0) {
            // Filter days based on search term
            filteredDays = specialDaysData.filter(day => 
                day.day.toLowerCase().includes(searchTerm) || 
                day.description.toLowerCase().includes(searchTerm) ||
                day.category.toLowerCase().includes(searchTerm)
            );
            
            // Highlight search term in calendar
            highlightSearchResults(searchTerm);
        } else {
            // Reset to current filter
            filteredDays = selectedCategory === 'all' 
                ? specialDaysData 
                : specialDaysData.filter(day => day.category === selectedCategory);
            renderCalendar();
        }
    });
    
    // Close details panel
    closeDetailsBtn.addEventListener('click', () => {
        dayDetails.classList.remove('active');
    });
    
    // Close details when clicking outside
    document.addEventListener('click', (e) => {
        if (!dayDetails.contains(e.target) && !e.target.closest('.calendar-day')) {
            dayDetails.classList.remove('active');
        }
    });
}

// Highlight search results in calendar
function highlightSearchResults(searchTerm) {
    const days = document.querySelectorAll('.calendar-day:not(.empty)');
    
    days.forEach(day => {
        const dateStr = day.dataset.date;
        const matchingEvents = specialDaysData.filter(event => 
            event.date === dateStr && (
                event.day.toLowerCase().includes(searchTerm) || 
                event.description.toLowerCase().includes(searchTerm) ||
                event.category.toLowerCase().includes(searchTerm)
            )
        );
        
        if (matchingEvents.length > 0) {
            day.style.boxShadow = '0 0 0 2px #2563eb';
            day.style.transform = 'scale(1.02)';
        } else {
            day.style.boxShadow = '';
            day.style.transform = '';
        }
    });
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', initApp);

// Initialize the application
async function initApp() {
    // Show loading
    showLoading();
    
    // Check backend health first
    const isHealthy = await checkBackendHealth();
    
    if (isHealthy) {
        await fetchSpecialDays();
        hideLoading();
        updateStats();
        updateTodayHighlight();
        renderCalendar();
        setupEventListeners();
        updateConnectionStatus(true);
    } else {
        hideLoading();
        showError("Cannot connect to backend server. Please try again later.");
        updateConnectionStatus(false);
    }
}

// Check backend health
async function checkBackendHealth() {
    try {
        const response = await fetch('/api/health', {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Backend health check:', data);
        return data.status === 'healthy';
    } catch (error) {
        console.error('Health check failed:', error);
        return false;
    }
}

// Update connection status UI
function updateConnectionStatus(connected) {
    let statusEl = document.querySelector('.connection-status');
    
    if (!statusEl) {
        statusEl = document.createElement('div');
        statusEl.className = 'connection-status';
        document.body.appendChild(statusEl);
    }
    
    if (connected) {
        statusEl.textContent = '✅ Backend Connected';
        statusEl.className = 'connection-status connected';
    } else {
        statusEl.textContent = '❌ Backend Disconnected';
        statusEl.className = 'connection-status disconnected';
    }
}

// Show loading overlay
function showLoading() {
    let loadingEl = document.querySelector('.loading-overlay');
    if (!loadingEl) {
        loadingEl = document.createElement('div');
        loadingEl.className = 'loading-overlay';
        loadingEl.innerHTML = '<div>Loading Special Days Calendar...</div>';
        document.body.appendChild(loadingEl);
    }
}

// Hide loading overlay
function hideLoading() {
    const loadingEl = document.querySelector('.loading-overlay');
    if (loadingEl) {
        loadingEl.remove();
    }
}

// Show error message
function showError(message) {
    const errorEl = document.createElement('div');
    errorEl.className = 'error-message';
    errorEl.innerHTML = `
        <h3>Connection Error</h3>
        <p>${message}</p>
        <button onclick="retryConnection()" style="margin-top: 10px; padding: 8px 16px; background: #C62828; color: white; border: none; border-radius: 4px; cursor: pointer;">
            Retry Connection
        </button>
    `;
    
    const container = document.querySelector('.container');
    container.prepend(errorEl);
}

// Retry connection
async function retryConnection() {
    document.querySelector('.error-message')?.remove();
    await initApp();
}

// Fetch special days from server
async function fetchSpecialDays() {
    try {
        const response = await fetch('/api/special-days');
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        specialDaysData = await response.json();
        console.log(`Successfully loaded ${specialDaysData.length} special days`);
    } catch (error) {
        console.error('Error fetching special days:', error);
        throw error;
    }
}

// ... REST OF YOUR ORIGINAL script.js FUNCTIONS ...
// (Keep all your existing functions: updateStats, updateTodayHighlight, renderCalendar, showDayDetails, etc.)

// Setup event listeners
function setupEventListeners() {
    prevMonthBtn.addEventListener('click', () => {
        currentMonth--;
        if (currentMonth < 0) {
            currentMonth = 11;
            currentYear--;
        }
        renderCalendar();
    });
    
    nextMonthBtn.addEventListener('click', () => {
        currentMonth++;
        if (currentMonth > 11) {
            currentMonth = 0;
            currentYear++;
        }
        renderCalendar();
    });
    
    todayBtn.addEventListener('click', () => {
        currentDate = new Date();
        currentMonth = currentDate.getMonth();
        currentYear = currentDate.getFullYear();
        renderCalendar();
        updateTodayHighlight();
    });
    
    // ... add other event listeners as needed
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', initApp);