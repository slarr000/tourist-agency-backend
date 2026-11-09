import { useState, type FormEvent } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  Alert,
  Avatar,
  Box,
  Button,
  CircularProgress,
  Paper,
  TextField,
  Typography,
} from '@mui/material';
import FlightTakeoffRoundedIcon from '@mui/icons-material/FlightTakeoffRounded';
import { apiRequest } from '../lib/api';
import ThemeToggle, { type ThemeMode } from '../components/ThemeToggle';

interface EmployeeIdentity {
  login: string;
  role: string;
}

interface AdminLoginProps {
  themeMode: ThemeMode;
  onToggleTheme: () => void;
  onLogin: (employee: EmployeeIdentity) => void;
  initialError?: string;
}

export default function AdminLogin({
  themeMode,
  onToggleTheme,
  onLogin,
  initialError,
}: AdminLoginProps) {
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(initialError ?? '');
  const [loading, setLoading] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError('');
    setLoading(true);

    try {
      const employee = await apiRequest<EmployeeIdentity>('/api/Auth/login', {
        method: 'POST',
        body: JSON.stringify({ login, password }),
      });
      onLogin(employee);

      const requestedPath = (location.state as { from?: { pathname?: string } } | null)?.from?.pathname;
      const destination = requestedPath?.startsWith('/admin/')
        && requestedPath !== '/admin/login'
        ? requestedPath
        : '/admin';
      navigate(destination, { replace: true });
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Не удалось войти в систему.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', display: 'grid', placeItems: 'center', p: 2, position: 'relative' }}>
      <Box sx={{ position: 'absolute', top: 20, right: 20 }}>
        <ThemeToggle mode={themeMode} onToggle={onToggleTheme} />
      </Box>
      <Paper
        elevation={0}
        sx={{
          width: '100%',
          maxWidth: 440,
          p: { xs: 3, sm: 5 },
          border: '1px solid',
          borderColor: 'divider',
          borderRadius: 5,
          background: 'linear-gradient(145deg, var(--color-surface-solid), var(--color-bg-soft))',
        }}
      >
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', mb: 3 }}>
          <Avatar
            variant="rounded"
            sx={{
              width: 54,
              height: 54,
              mb: 2,
              borderRadius: 3,
              color: '#06221f',
              background: 'linear-gradient(145deg, #a4f3e5, #46c5b0)',
            }}
          >
            <FlightTakeoffRoundedIcon />
          </Avatar>
          <Typography variant="h4" sx={{ fontWeight: 800, letterSpacing: '-0.04em' }}>
            Вход сотрудников
          </Typography>
          <Typography color="text.secondary" sx={{ mt: 1, textAlign: 'center' }}>
            Войдите в рабочее пространство IS Tour
          </Typography>
        </Box>

        <Box component="form" onSubmit={handleSubmit}>
          <TextField
            autoFocus
            fullWidth
            autoComplete="username"
            label="Логин сотрудника"
            value={login}
            onChange={(event) => setLogin(event.target.value)}
            margin="normal"
            required
          />
          <TextField
            fullWidth
            autoComplete="current-password"
            label="Пароль"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            margin="normal"
            required
          />
          {error && <Alert severity="error" sx={{ mt: 2 }}>{error}</Alert>}
          <Button
            fullWidth
            type="submit"
            variant="contained"
            disabled={loading}
            sx={{ mt: 3, minHeight: 48 }}
          >
            {loading ? <CircularProgress size={22} color="inherit" /> : 'Войти в систему'}
          </Button>
        </Box>
      </Paper>
    </Box>
  );
}
