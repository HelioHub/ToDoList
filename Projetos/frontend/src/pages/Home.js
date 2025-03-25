import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const Home = () => {
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();

  // Adicione interceptadores para debug (opcional)
  axios.interceptors.request.use(request => {
    console.log('Starting Request', request);
    return request;
  });

  axios.interceptors.response.use(response => {
    console.log('Response:', response);
    return response;
  });

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      console.log('Enviando requisição de login...');
      console.log('Login:', login);
      console.log('Password:', password);

      // REQUISIÇÃO MODIFICADA PARA USAR O PROXY
      const response = await axios.post('/api/login', {
        login,
        password,
      });

      console.log('Resposta recebida:', response);
      localStorage.setItem('token', response.data);
      navigate('/dashboard');
    } catch (error) {
      console.error('Erro ao fazer login:', error);
      alert('Login ou senha inválidos');
    }
  };

  return (
    <div style={styles.container}>
      <h2>Acesso</h2>
      <form onSubmit={handleLogin} style={styles.form}>
        <div style={styles.formGroup}>
          <label>Usuário</label>
          <input
            type="text"
            value={login}
            onChange={(e) => setLogin(e.target.value)}
            style={styles.input}
          />
        </div>
        <div style={styles.formGroup}>
          <label>Senha</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={styles.input}
          />
        </div>
        <button type="submit" style={styles.button}>Entrar</button>
      </form>
    </div>
  );
};

// Estilos melhorados
const styles = {
  container: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    height: '100vh',
    backgroundColor: '#f5f5f5',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '15px',
    width: '300px',
    padding: '20px',
    backgroundColor: 'white',
    borderRadius: '8px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
  },
  formGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '5px',
  },
  input: {
    padding: '8px',
    border: '1px solid #ddd',
    borderRadius: '4px',
  },
  button: {
    padding: '10px',
    backgroundColor: '#007bff',
    color: 'white',
    border: 'none',
    borderRadius: '4px',
    cursor: 'pointer',
    marginTop: '10px',
  },
};

export default Home;