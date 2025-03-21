import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Grid from '../components/Grid';
import Form from '../components/Form';

const Tasks = () => {
  const [tasks, setTasks] = useState([]);
  const [selectedTask, setSelectedTask] = useState(null);

  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = async () => {
    const token = localStorage.getItem('token');
    const response = await axios.get('http://localhost:9000/todolist', {
      headers: { Authorization: `Bearer ${token}` },
    });
    setTasks(response.data);
  };

  const handleSave = async (task) => {
    const token = localStorage.getItem('token');
    if (task.idtodolist) {
      await axios.put(`http://localhost:9000/todolist/${task.idtodolist}`, task, {
        headers: { Authorization: `Bearer ${token}` },
      });
    } else {
      await axios.post('http://localhost:9000/todolist', task, {
        headers: { Authorization: `Bearer ${token}` },
      });
    }
    fetchTasks();
    setSelectedTask(null);
  };

  const handleDelete = async (task) => {
    const token = localStorage.getItem('token');
    await axios.delete(`http://localhost:9000/todolist/${task.idtodolist}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    fetchTasks();
  };

  return (
    <div style={styles.container}>
      <h2>Cadastro de Tarefas</h2>
      <Form initialData={selectedTask} onSubmit={handleSave} />
      <Grid data={tasks} onEdit={setSelectedTask} onDelete={handleDelete} />
    </div>
  );
};

const styles = {
  container: {
    padding: '20px',
  },
};

export default Tasks;