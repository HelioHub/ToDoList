import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Grid from '../components/Grid';
import Form from '../components/Form';

const Users = () => {
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {

    const token = localStorage.getItem('token');
    const response = await axios.get('http://localhost:9000/users', {
      headers: { Authorization: `Bearer ${token}` },
    });
	
    setUsers(response.data);
  };

  const handleSave = async (user) => {
    const token = localStorage.getItem('token');
    if (user.iduser) {
      await axios.put(`http://localhost:9000/users/${user.iduser}`, user, {
        headers: { Authorization: `Bearer ${token}` },
      });
    } else {
      await axios.post('http://localhost:9000/users', user, {
        headers: { Authorization: `Bearer ${token}` },
      });
    }
    fetchUsers();
    setSelectedUser(null);
  };

  const handleDelete = async (user) => {
    const token = localStorage.getItem('token');
    await axios.delete(`http://localhost:9000/users/${user.iduser}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    fetchUsers();
  };

  return (
    <div style={styles.container}>
      <h2>Cadastro de Usuários</h2>
      <Form initialData={selectedUser} onSubmit={handleSave} />
      <Grid data={users} onEdit={setSelectedUser} onDelete={handleDelete} />
    </div>
  );
};

const styles = {
  container: {
    padding: '20px',
  },
};

export default Users;