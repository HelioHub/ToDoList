import React from 'react';
import { Link } from 'react-router-dom';

const Dashboard = () => {
  return (
    <div style={styles.container}>
      <h2>Dashboard</h2>
      <nav style={styles.nav}>
        <Link to="/users">Cadastro de Usuários</Link>
        <Link to="/tasks">Cadastro de Tarefas</Link>
      </nav>
    </div>
  );
};

const styles = {
  container: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    height: '100vh',
  },
  nav: {
    display: 'flex',
    gap: '20px',
  },
};

export default Dashboard;