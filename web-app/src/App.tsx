import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import './App.css'

function App() {
  const { t, i18n } = useTranslation()
  const [activePage, setActivePage] = useState('home')

  const changeLanguage = (lng: string) => {
    i18n.changeLanguage(lng)
  }

  const renderPage = () => {
    switch (activePage) {
      case 'home':
        return (
          <div className="page">
            <h1>{t('home.welcome')}</h1>
            <p>{t('home.description')}</p>
            <button className="btn">{t('home.tryNow')}</button>
          </div>
        )
      case 'settings':
        return (
          <div className="page">
            <h1>{t('settings.title')}</h1>
            <div className="setting-group">
              <label>{t('settings.defaultAiModel')}</label>
              <select>
                <option value="gpt-4o-mini">GPT-4o-mini</option>
                <option value="deepseek-3.2">DeepSeek 3.2</option>
                <option value="qwen-plus">Qwen-Plus</option>
              </select>
            </div>
            <div className="setting-group">
              <label>{t('settings.writingStyle')}</label>
              <div>
                <label>{t('settings.tone')}</label>
                <select>
                  <option value="professional">{t('settings.professional')}</option>
                  <option value="casual">{t('settings.casual')}</option>
                  <option value="formal">{t('settings.formal')}</option>
                </select>
              </div>
              <div>
                <label>{t('settings.length')}</label>
                <select>
                  <option value="short">{t('settings.short')}</option>
                  <option value="medium">{t('settings.medium')}</option>
                  <option value="long">{t('settings.long')}</option>
                </select>
              </div>
            </div>
            <button className="btn">{t('common.button.save')}</button>
          </div>
        )
      case 'prompts':
        return (
          <div className="page">
            <h1>{t('prompts.title')}</h1>
            <button className="btn">{t('prompts.addPrompt')}</button>
            <div className="prompts-list">
              <h2>{t('prompts.defaultPrompts')}</h2>
              <div className="prompt-item">
                <h3>Professional Email</h3>
                <p>Write a professional email...</p>
              </div>
              <h2>{t('prompts.customPrompts')}</h2>
              <div className="prompt-item">
                <h3>Meeting Notes</h3>
                <p>Summarize meeting notes...</p>
                <div className="prompt-actions">
                  <button className="btn-sm">{t('common.button.edit')}</button>
                  <button className="btn-sm">{t('common.button.delete')}</button>
                </div>
              </div>
            </div>
          </div>
        )
      case 'apiKeys':
        return (
          <div className="page">
            <h1>{t('apiKeys.title')}</h1>
            <div className="api-key-form">
              <div className="form-group">
                <label>{t('apiKeys.openai')}</label>
                <input type="password" placeholder={t('apiKeys.enterKey')} />
                <button className="btn">{t('apiKeys.saveKey')}</button>
              </div>
              <div className="form-group">
                <label>{t('apiKeys.deepseek')}</label>
                <input type="password" placeholder={t('apiKeys.enterKey')} />
                <button className="btn">{t('apiKeys.saveKey')}</button>
              </div>
              <div className="form-group">
                <label>{t('apiKeys.qwen')}</label>
                <input type="password" placeholder={t('apiKeys.enterKey')} />
                <button className="btn">{t('apiKeys.saveKey')}</button>
              </div>
            </div>
          </div>
        )
      default:
        return (
          <div className="page">
            <h1>{t('home.welcome')}</h1>
            <p>{t('home.description')}</p>
          </div>
        )
    }
  }

  return (
    <div className="app">
      <header className="app-header">
        <div className="logo">
          <img src="/logo.png" alt="Pen AI" />
          <h1>Pen AI</h1>
        </div>
        <div className="language-selector">
          <button onClick={() => changeLanguage('en')}>EN</button>
          <button onClick={() => changeLanguage('zh')}>中文</button>
        </div>
      </header>
      <nav className="app-nav">
        <button 
          className={activePage === 'home' ? 'nav-btn active' : 'nav-btn'}
          onClick={() => setActivePage('home')}
        >
          {t('nav.home')}
        </button>
        <button 
          className={activePage === 'settings' ? 'nav-btn active' : 'nav-btn'}
          onClick={() => setActivePage('settings')}
        >
          {t('nav.settings')}
        </button>
        <button 
          className={activePage === 'prompts' ? 'nav-btn active' : 'nav-btn'}
          onClick={() => setActivePage('prompts')}
        >
          {t('nav.prompts')}
        </button>
        <button 
          className={activePage === 'apiKeys' ? 'nav-btn active' : 'nav-btn'}
          onClick={() => setActivePage('apiKeys')}
        >
          {t('nav.apiKeys')}
        </button>
      </nav>
      <main className="app-main">
        {renderPage()}
      </main>
      <footer className="app-footer">
        <p>© 2026 Pen AI. All rights reserved.</p>
      </footer>
    </div>
  )
}

export default App
