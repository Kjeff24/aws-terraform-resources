// Simple client-side interactions for the static site.
document.addEventListener('DOMContentLoaded', function(){
	// Year in footer
	const yearEl = document.getElementById('year');
	if(yearEl) yearEl.textContent = new Date().getFullYear();

	// Theme toggle (persist in localStorage)
	const themeToggle = document.getElementById('themeToggle');
	function toggleTheme(){
		const current = document.documentElement.getAttribute('data-theme') || '';
		if(current === 'dark'){
			document.documentElement.removeAttribute('data-theme');
			localStorage.removeItem('theme');
		} else {
			document.documentElement.setAttribute('data-theme','dark');
			localStorage.setItem('theme','dark');
		}
	}
	// Restore theme
	if(localStorage.getItem('theme') === 'dark') document.documentElement.setAttribute('data-theme','dark');
	if(themeToggle) themeToggle.addEventListener('click', toggleTheme);

	// Mobile nav toggle
	const mobileToggle = document.getElementById('mobileMenuToggle');
	const nav = document.getElementById('primaryNav');
	if(mobileToggle && nav) mobileToggle.addEventListener('click', ()=>{
		if(nav.style.display === 'flex') nav.style.display = 'none'; else nav.style.display = 'flex';
	});

	// Contact form stub
	const form = document.getElementById('contactForm');
	const toast = document.getElementById('toast');
	function showToast(msg){
		if(!toast) return;
		toast.textContent = msg;
		toast.style.display = 'block';
		setTimeout(()=>{ toast.style.display = 'none'; }, 3500);
	}

	if(form){
		form.addEventListener('submit', function(e){
			e.preventDefault();
			const fd = new FormData(form);
			// In a real site you'd POST this to an API or use a serverless function.
			console.log('Contact form data:', Object.fromEntries(fd.entries()));
			form.reset();
			showToast('Thanks — we received your message (demo).');
		});
	}

	// No dynamic README rendering; content is now embedded statically in index.html
});
