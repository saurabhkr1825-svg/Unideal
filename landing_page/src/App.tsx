import { useEffect, useState, useRef } from 'react';
import './App.css';

// Hook for scroll animation
function useIntersectionObserver(options = {}) {
  const elementsRef = useRef<(HTMLElement | null)[]>([]);

  useEffect(() => {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          // Optional: observer.unobserve(entry.target) if we only want it to fade in once
        }
      });
    }, { threshold: 0.1, ...options });

    const currentElements = elementsRef.current;
    
    currentElements.forEach((el) => {
      if (el) observer.observe(el);
    });

    return () => {
      currentElements.forEach((el) => {
        if (el) observer.unobserve(el);
      });
    };
  }, [options]);

  return (el: HTMLElement | null) => {
    if (el && !elementsRef.current.includes(el)) {
      elementsRef.current.push(el);
    }
  };
}

function App() {
  const [scrolled, setScrolled] = useState(false);
  const setRef = useIntersectionObserver();

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 50);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <div className="app-wrapper">
      <div className="bg-glow"></div>
      <div className="bg-glow right"></div>

      {/* Header */}
      <header className={`header ${scrolled ? 'scrolled' : ''}`}>
        <div className="container">
          <div className="logo text-gradient">Unideal</div>
          <nav className="nav-links">
            <a href="#features">Features</a>
            <a href="#preview">Preview</a>
            <a href="#about">About</a>
          </nav>
          <a href="https://unideal-app.vercel.app/" target="_blank" rel="noopener noreferrer" className="btn btn-primary" style={{ padding: '8px 16px', fontSize: '0.85rem' }}>Use Web App</a>
        </div>
      </header>

      {/* Hero Section */}
      <section className="hero">
        <div className="container hero-content fade-up" ref={setRef}>
          <div className="badge">v2.0 Beta Live ✨</div>
          <h1><span className="text-gradient">Unideal</span></h1>
          <p>
            Smart solutions for everyday problems. Experience the next generation of fast, seamless, and secure peer-to-peer commerce.
          </p>
          <div className="hero-buttons">
            <a href="https://github.com/saurabhkr1825-svg/Unideal/releases/download/v1.0/unideal.apk" target="_blank" rel="noopener noreferrer" className="btn btn-primary fade-up stagger-1" ref={setRef}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
              </svg>
              Download APK
            </a>
            <a href="https://unideal-app.vercel.app/" target="_blank" rel="noopener noreferrer" className="btn btn-outline fade-up stagger-2" ref={setRef}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="2" y1="12" x2="22" y2="12"></line>
                <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
              </svg>
              Use Web App
            </a>
          </div>
        </div>
      </section>

      {/* App Preview Section */}
      <section id="preview" className="app-preview container">
        <div className="section-header fade-up" ref={setRef}>
          <h2>See It In Action</h2>
          <p>A beautiful native experience right in your hands.</p>
        </div>
        <div className="phone-mockup fade-up stagger-1" ref={setRef}>
          <div className="phone-screen">
            {/* Mocking a beautiful app screen */}
            <div className="screen-header"></div>
            <div className="screen-card" style={{ height: '120px', flex: 'none' }}></div>
            <div className="screen-card"></div>
            <div className="screen-card"></div>
            <div className="screen-btn"></div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="features container">
        <div className="section-header fade-up" ref={setRef}>
          <h2>Why Choose Unideal?</h2>
          <p>Built with cutting-edge tech for the ultimate marketplace experience.</p>
        </div>
        
        <div className="features-grid">
          <div className="feature-card glass-panel fade-up stagger-1" ref={setRef}>
            <div className="feature-icon">⚡</div>
            <h3>Fast</h3>
            <p>Lightning-fast speeds. Our Supabase-powered backend ensures items are listed and updated instantly without any lag.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-2" ref={setRef}>
            <div className="feature-icon">✨</div>
            <h3>Simple UI</h3>
            <p>A clean, intuitive interface that makes buying, selling, and managing your items effortless and enjoyable.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-3" ref={setRef}>
            <div className="feature-icon">🛠️</div>
            <h3>Smart Tools</h3>
            <p>Built-in QR code transaction verification and dynamic bidding systems make trading simple and completely secure.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-4" ref={setRef}>
            <div className="feature-icon">🎈</div>
            <h3>Lightweight</h3>
            <p>Developed entirely in Flutter, the app takes up minimal space while delivering native performance down to 60fps.</p>
          </div>
        </div>
      </section>

      {/* About Section */}
      <section id="about" className="about-section fade-up" ref={setRef}>
        <div className="container">
          <div className="section-header">
            <h2>About The Project</h2>
            <p>An innovative idea brought to life.</p>
          </div>
          <p style={{ maxWidth: '800px', margin: '0 auto', fontSize: '1.2rem', color: 'var(--text-secondary)' }}>
            Unideal is a student-built project aiming to solve everyday commerce problems. We believe in providing smart, lightweight, and incredibly fast tools that empower people to trade seamlessly. From secure handoffs to real-time auctioning, Unideal is the marketplace created with true user needs in mind.
          </p>
        </div>
      </section>

      {/* Call To Action */}
      <section id="download" className="cta-section fade-up" ref={setRef}>
        <div className="container">
          <h2>Ready to upgrade your trading experience?</h2>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '32px', fontSize: '1.1rem' }}>
            Download the app today or launch the web version instantly.
          </p>
          <div className="hero-buttons">
            <a href="https://github.com/saurabhkr1825-svg/Unideal/releases/download/v1.0/unideal.apk" target="_blank" rel="noopener noreferrer" className="btn btn-primary">Download APK</a>
            <a href="https://unideal-app.vercel.app/" target="_blank" rel="noopener noreferrer" className="btn btn-outline">Start Web App</a>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="container">
          <div className="footer-content">
            <div className="logo text-gradient" style={{ fontSize: '1.25rem' }}>Unideal</div>
            <div className="nav-links">
              <a href="mailto:contact@unideal.app">Contact Us</a>
              <a href="https://github.com/Saurabhkr1825/Unideal" target="_blank" rel="noopener noreferrer">GitHub</a>
            </div>
          </div>
          <p className="footer-text">© {new Date().getFullYear()} Unideal. Crafted by students for a smarter future.</p>
        </div>
      </footer>
    </div>
  );
}

export default App;
