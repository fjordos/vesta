import React from 'react';
import { createRoot } from 'react-dom/client';
import { Provider } from 'react-redux';
import configureStore from './store';
import './index.css';
import App from './containers/App/App';
import * as serviceWorker from './containers/App/serviceWorker';
import { BrowserRouter as Router } from 'react-router-dom';

const container = document.getElementById('root');
const root = createRoot(container);

root.render(
  <Provider store={configureStore()}>
    <Router>
      <App />
    </Router>
  </Provider>
);

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: http://bit.ly/CRA-PWA
serviceWorker.unregister();
