import React from 'react';

const Footer = () => {
  return (
    <footer style={styles.footer}>
      <p>&copy; 2025 To-Do List</p>
    </footer>
  );
};

const styles = {
  footer: {
    backgroundColor: '#282c34',
    color: 'white',
    padding: '10px 20px',
    textAlign: 'center',
    position: 'fixed',
    bottom: '0',
    width: '100%',
  },
};

export default Footer;