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
          <p style={{ fontSize: '1.2rem', fontWeight: 500, color: 'var(--text-primary)' }}>
            From Seniors to Freshers — Smarter Campus Marketplace
          </p>
          <p style={{ marginBottom: '2rem' }}>
            Buy, sell, or donate essentials within your campus.<br />
            Save money, reduce waste, and help your juniors.
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
          <p className="fade-up stagger-3" ref={setRef} style={{ marginTop: '1.25rem', color: 'var(--text-secondary)', fontSize: '0.95rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
             <span style={{ display: 'inline-block', width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#4ade80', boxShadow: '0 0 8px #4ade80' }}></span>
             v1.0 • 500+ Downloads
          </p>
        </div>
      </section>

      {/* Problem Section */}
      <section id="problem" className="about-section fade-up" ref={setRef}>
        <div className="container">
          <div className="section-header">
            <h2>The Problem</h2>
            <p style={{ maxWidth: '800px', margin: '0 auto', color: 'var(--text-secondary)' }}>
              Every year, final-year students leave campus with useful items they no longer need —<br/>
              books, mattresses, buckets, lab equipment, and more.
            </p>
          </div>
          <p style={{ maxWidth: '800px', margin: '0 auto', fontSize: '1.2rem', color: 'var(--text-secondary)' }}>
            At the same time, first-year students arrive and spend thousands buying the same items. There is no simple platform to connect them. As a result:
          </p>
          <div className="features-grid" style={{ marginTop: '2.5rem' }}>
            <div className="feature-card glass-panel stagger-1 fade-up" ref={setRef} style={{ textAlign: 'center', padding: '1.5rem' }}>
              <div className="feature-icon" style={{ color: '#ff4b4b' }}>❌</div>
              <h3 style={{ marginBottom: 0 }}>Items go to waste</h3>
            </div>
            <div className="feature-card glass-panel stagger-2 fade-up" ref={setRef} style={{ textAlign: 'center', padding: '1.5rem' }}>
              <div className="feature-icon" style={{ color: '#ff4b4b' }}>❌</div>
              <h3 style={{ marginBottom: 0 }}>Juniors overspend</h3>
            </div>
            <div className="feature-card glass-panel stagger-3 fade-up" ref={setRef} style={{ textAlign: 'center', padding: '1.5rem' }}>
              <div className="feature-icon" style={{ color: '#ff4b4b' }}>❌</div>
              <h3 style={{ marginBottom: 0 }}>No trusted student marketplace</h3>
            </div>
          </div>
        </div>
      </section>

      {/* Solution Section */}
      <section id="solution" className="app-preview container fade-up" ref={setRef} style={{ paddingBottom: '2rem' }}>
        <div className="section-header">
          <h2>Our Solution</h2>
          <p>Unideal connects students within campuses to create a trusted marketplace.</p>
        </div>
        <div className="features-grid">
          <div className="feature-card glass-panel fade-up stagger-1" ref={setRef}>
            <div className="feature-icon">📦</div>
            <h3>Sell easily</h3>
            <p>Sell your used items easily without any hassle.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-2" ref={setRef}>
            <div className="feature-icon">💸</div>
            <h3>Low prices</h3>
            <p>Buy essentials at incredibly low prices.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-3" ref={setRef}>
            <div className="feature-icon">🎁</div>
            <h3>Donate</h3>
            <p>Donate items to help your juniors in need.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-4" ref={setRef}>
            <div className="feature-icon">🏫</div>
            <h3>Campus-specific</h3>
            <p>Campus-based connections ensuring complete safety and trust.</p>
          </div>
        </div>
        
        <div className="fade-up" ref={setRef} style={{ textAlign: 'center', marginTop: '4rem', padding: '2rem', background: 'rgba(255,255,255,0.03)', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.05)' }}>
          <p style={{ fontSize: '1.4rem', fontWeight: 'bold', margin: 0, color: 'var(--text-primary)' }}>
            Built <span className="text-gradient">by students</span>, <span className="text-gradient">for students</span>.
          </p>
        </div>
      </section>

      {/* How Buying Works Section */}
      <section id="how-buying-works" className="app-preview container fade-up" ref={setRef} style={{ paddingBottom: '4rem' }}>
        <div className="section-header">
          <h2>How Buying Works</h2>
          <p>Unideal enables simple, safe, and direct student-to-student transactions.</p>
        </div>
        <div className="features-grid">
          <div className="feature-card glass-panel fade-up stagger-1" ref={setRef}>
            <div className="feature-icon">🛒</div>
            <h3>Send Request</h3>
            <p>Buyer sends a request for an item with pickup details.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-2" ref={setRef}>
            <div className="feature-icon">📍</div>
            <h3>Share Location</h3>
            <p>Share your Hostel name, Room no, and meeting point.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-3" ref={setRef}>
            <div className="feature-icon">📩</div>
            <h3>Seller Decision</h3>
            <p>Seller reviews the request and accepts or rejects it.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-4" ref={setRef}>
            <div className="feature-icon">🤝</div>
            <h3>Hand-to-Hand</h3>
            <p>Meet up on campus and exchange the item directly.</p>
          </div>
        </div>
        <div className="fade-up" ref={setRef} style={{ textAlign: 'center', marginTop: '2rem', padding: '1.5rem', background: 'rgba(74, 222, 128, 0.05)', borderRadius: '16px', border: '1px solid rgba(74, 222, 128, 0.1)' }}>
          <p style={{ fontSize: '1.2rem', fontWeight: 'bold', margin: 0, color: '#4ade80' }}>
            No online payment. No risk. Just simple deals.
          </p>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="features container">
        <div className="section-header fade-up" ref={setRef}>
          <h2>Features & Why Choose Unideal?</h2>
          <p>Everything you need for a seamless trading experience.</p>
        </div>
        <div className="features-grid">
          <div className="feature-card glass-panel fade-up stagger-1" ref={setRef}>
            <div className="feature-icon">🔍</div>
            <h3>Easy Search & Listing</h3>
            <p>Find what you need instantly or list your items in seconds.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-2" ref={setRef}>
            <div className="feature-icon">💬</div>
            <h3>Direct Chat</h3>
            <p>Secure, direct chat between students to coordinate handoffs.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-3" ref={setRef}>
            <div className="feature-icon">💰</div>
            <h3>Save Money & Reduce Waste</h3>
            <p>Save money as a student while reducing overall waste on your campus.</p>
          </div>
          <div className="feature-card glass-panel fade-up stagger-4" ref={setRef}>
            <div className="feature-icon">🤝</div>
            <h3>Build Community</h3>
            <p>Fast, secure, and incredibly easy to use while building local student connections.</p>
          </div>
        </div>
      </section>

      {/* Call To Action */}
      <section id="download" className="cta-section fade-up" ref={setRef}>
        <div className="container">
          <h2>Start Using Unideal Today</h2>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '32px', fontSize: '1.2rem' }}>
            Join your campus marketplace now. <br/>
            <b>Built by students, for students.</b>
          </p>
          <div className="hero-buttons" style={{ justifyContent: 'center' }}>
            <a href="https://github.com/saurabhkr1825-svg/Unideal/releases/download/v1.0/unideal.apk" target="_blank" rel="noopener noreferrer" className="btn btn-primary">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ marginRight: '8px' }}>
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
              </svg>
              Download APK
            </a>
            <a href="https://unideal-app.vercel.app/" target="_blank" rel="noopener noreferrer" className="btn btn-outline">
              Start Web App
            </a>
          </div>
          <p style={{ marginTop: '1.25rem', color: 'var(--text-secondary)', fontSize: '0.95rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
             <span style={{ display: 'inline-block', width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#4ade80', boxShadow: '0 0 8px #4ade80' }}></span>
             v1.0 • 500+ Downloads
          </p>
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
