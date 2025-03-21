import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const Home = () => {
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();

	const handleLogin = async (e) => {
	  e.preventDefault();
	  try {
		console.log('Enviando requisição de login...'); // Log para depuração
		console.log('Login:', login); // Log para depuração
		console.log('Password:', password); // Log para depuração

		const response = await axios.post('http://localhost:9000/login', {
		  login,
		  password,
		});

		console.log('Resposta recebida:', response); // Log para depuração
		localStorage.setItem('token', response.data);
		navigate('/dashboard');
	  } catch (error) {
		console.error('Erro ao fazer login:', error); // Log para depuração
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
          />
        </div>
        <div style={styles.formGroup}>
          <label>Senha</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </div>
        <button type="submit">Entrar</button>
      </form>
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
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '10px',
  },
  formGroup: {
    display: 'flex',
    flexDirection: 'column',
  },
};

export default Home;