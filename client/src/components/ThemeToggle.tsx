import { IconButton, Tooltip } from '@mui/material';
import DarkModeRoundedIcon from '@mui/icons-material/DarkModeRounded';
import LightModeRoundedIcon from '@mui/icons-material/LightModeRounded';

export type ThemeMode = 'light' | 'dark';

interface ThemeToggleProps {
  mode: ThemeMode;
  onToggle: () => void;
}

const ThemeToggle = ({ mode, onToggle }: ThemeToggleProps) => {
  const nextMode = mode === 'dark' ? 'light' : 'dark';

  return (
    <Tooltip title={`Включить ${nextMode === 'light' ? 'светлую' : 'темную'} тему`}>
      <IconButton
        onClick={onToggle}
        aria-label={`Включить ${nextMode === 'light' ? 'светлую' : 'темную'} тему`}
        color="inherit"
        className="theme-toggle"
        sx={{ width: 40, height: 40, border: '1px solid var(--color-line)', color: 'text.primary' }}
      >
        {mode === 'dark' ? <LightModeRoundedIcon fontSize="small" /> : <DarkModeRoundedIcon fontSize="small" />}
      </IconButton>
    </Tooltip>
  );
};

export default ThemeToggle;
