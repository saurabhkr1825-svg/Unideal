import './App.css';

function App() {
  return (
    <>
      {/* NAVBAR */}
      <header>
        <h2>Unideal</h2>
        <a href="https://unideal-app.vercel.app/">
          <button style={{ background: '#7c6cff', border: 'none', padding: '10px 18px', color: 'white', borderRadius: '8px', cursor: 'pointer' }}>Use Web App</button>
        </a>
      </header>

      {/* HERO */}
      <section className="hero">
        <h1>Smarter Campus Marketplace</h1>

        <p>
          Buy, sell, or donate essentials within your campus.
          Save money, reduce waste, and help your juniors.
        </p>

        <a href="https://github.com/saurabhkr1825-svg/Unideal/releases/download/v1.0/unideal.apk" target="_blank" rel="noopener noreferrer">
          <button className="btn primary">Download APK</button>
        </a>

        <a href="https://unideal-app.vercel.app/" style={{ marginLeft: '10px' }}>
          <button className="btn secondary">Use Web App</button>
        </a>
      </section>

      {/* PROBLEM */}
      <section>
        <h2>The Problem</h2>

        <p>
          Every year, seniors leave campus with useful items while freshers
          spend thousands buying the same things again.
        </p>

        <ul>
          <li>❌ Items go to waste</li>
          <li>❌ Students overspend</li>
          <li>❌ No trusted platform</li>
        </ul>
      </section>

      {/* SOLUTION */}
      <section>
        <h2>Our Solution</h2>

        <p>
          Unideal connects students within campuses to buy, sell, or donate items easily.
        </p>

        <ul>
          <li>📦 Sell items easily</li>
          <li>💸 Buy at low prices</li>
          <li>🎁 Donate to juniors</li>
          <li>🏫 Campus-based marketplace</li>
        </ul>

        <p style={{ marginTop: '20px' }}><b>Built by students, for students.</b></p>
      </section>

      {/* CTA */}
      <section>
        <h2>Start Using Unideal Today</h2>

        <a href="https://github.com/saurabhkr1825-svg/Unideal/releases/download/v1.0/unideal.apk" target="_blank" rel="noopener noreferrer">
          <button className="btn primary">Download APK</button>
        </a>
      </section>

      {/* FOOTER */}
      <footer>
        <p>© {new Date().getFullYear()} Unideal. All rights reserved.</p>
      </footer>
    </>
  );
}

export default App;
