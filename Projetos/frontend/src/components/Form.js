import React, { useState } from 'react';

const Form = ({ initialData, onSubmit }) => {
  const [formData, setFormData] = useState(initialData || {});

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} style={styles.form}>
      {Object.keys(formData).map((key) => (
        <div key={key} style={styles.formGroup}>
          <label>{key}</label>
          <input
            type="text"
            name={key}
            value={formData[key] || ''}
            onChange={handleChange}
          />
        </div>
      ))}
      <button type="submit">Salvar</button>
    </form>
  );
};

const styles = {
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

export default Form;