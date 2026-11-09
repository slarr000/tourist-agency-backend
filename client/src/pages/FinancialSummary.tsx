import React, { useState } from 'react';
import { Alert, Box, Typography, Paper, TextField, Button, Grid } from '@mui/material';
import CalculateIcon from '@mui/icons-material/Calculate';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import { apiRequest } from '../lib/api';

// 1. СТРОГИЙ КОНТРАКТ ДАННЫХ
interface IFinancialReport {
    totalIncome: number;
    totalExpense: number;
    netProfit: number;
}

const FinancialSummary: React.FC = () => {
    const [report, setReport] = useState<IFinancialReport | null>(null);
    const [startDate, setStartDate] = useState<string>('');
    const [endDate, setEndDate] = useState<string>('');
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string | null>(null);

    const fetchData = async () => {
        if (!startDate || !endDate) {
            setError('Выберите начало и конец периода.');
            return;
        }

        if (startDate > endDate) {
            setError('Начало периода не может быть позже его окончания.');
            return;
        }

        setLoading(true);
        setError(null);
        try {
            const params = new URLSearchParams({ startDate, endDate });
            const result = await apiRequest<IFinancialReport>(`/api/Reports/financial-summary?${params.toString()}`);
            setReport(result);
        } catch (error) {
            setError(error instanceof Error ? error.message : 'Не удалось загрузить финансовый отчет.');
        } finally {
            setLoading(false);
        }
    };

    const glassStyle = {
        backgroundColor: 'rgba(18, 18, 18, 0.4)',
        backdropFilter: 'blur(12px)',
        borderRadius: '16px',
        border: '1px solid rgba(255, 255, 255, 0.05)',
        boxShadow: '0 8px 32px rgba(0,0,0,0.2)',
        p: 3
    };

    const inputStyles = {
        input: { color: '#fff' },
        '& .MuiInputLabel-root': { color: '#888' },
        '& .MuiOutlinedInput-root': {
            backgroundColor: 'rgba(255,255,255,0.03)',
            borderRadius: '8px',
            '& fieldset': { borderColor: 'rgba(255,255,255,0.1)' },
            '&:hover fieldset': { borderColor: 'rgba(255,255,255,0.2)' },
            '&.Mui-focused fieldset': { borderColor: '#4caf50', borderWidth: '1px' }
        }
    };

    return (
        <Box sx={{ maxWidth: '1200px', margin: '0 auto', animation: 'fadeIn 0.5s ease-in-out' }}>
            
            {/* Заголовок */}
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 4 }}>
                <Box sx={{ p: 1, borderRadius: '10px', backgroundColor: 'rgba(76, 175, 80, 0.1)', border: '1px solid rgba(76, 175, 80, 0.2)' }}>
                    <AccountBalanceWalletIcon sx={{ color: '#4caf50', fontSize: 24, display: 'block' }} />
                </Box>
                <Box>
                    <Typography variant="h4" sx={{ fontWeight: 800, color: '#fff', letterSpacing: '-0.5px' }}>
                        Финансовый отчет
                    </Typography>
                    <Typography variant="body1" sx={{ color: '#888', mt: 0.5 }}>
                        Анализ доходов, расходов и чистой прибыли за выбранный период
                    </Typography>
                </Box>
            </Box>

            {/* Панель фильтров */}
            <Paper sx={{ ...glassStyle, display: 'flex', gap: 2, alignItems: 'center', mb: 4, flexWrap: 'wrap' }}>
                <TextField 
                    type="date" 
                    label="Начало периода" 
                    value={startDate} 
                    onChange={e => setStartDate(e.target.value)} 
                    sx={inputStyles}
                    slotProps={{ inputLabel: { shrink: true } }}
                />
                <TextField 
                    type="date" 
                    label="Конец периода" 
                    value={endDate} 
                    onChange={e => setEndDate(e.target.value)} 
                    sx={inputStyles}
                    slotProps={{ inputLabel: { shrink: true } }}
                />
                <Button 
                    variant="contained" 
                    startIcon={<CalculateIcon />} 
                    onClick={fetchData}
                    disabled={loading}
                    sx={{ 
                        backgroundColor: '#4caf50', color: '#000', fontWeight: 600, 
                        height: '56px', borderRadius: '8px', px: 4,
                        '&:hover': { backgroundColor: '#388e3c' },
                        '&.Mui-disabled': { backgroundColor: 'rgba(76, 175, 80, 0.3)', color: '#888' }
                    }}
                >
                    {loading ? 'Расчет...' : 'Рассчитать финансы'}
                </Button>
            </Paper>
            {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

            {/* Результаты (Карточки) */}
   {/* Результаты (Карточки) */}
            {report && (
                <Grid container spacing={3} sx={{ animation: 'slideUp 0.4s ease-out' }}>
                    {/* Доходы */}
                    <Grid size={{ xs: 12, md: 4 }}>
                        <Paper sx={{ ...glassStyle, borderTop: '4px solid #4caf50' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                                <Typography variant="body2" sx={{ color: '#888', fontWeight: 600, textTransform: 'uppercase' }}>
                                    Общий доход
                                </Typography>
                                <TrendingUpIcon sx={{ color: '#4caf50' }} />
                            </Box>
                            <Typography variant="h4" sx={{ color: '#fff', fontWeight: 700 }}>
                                + {report.totalIncome.toLocaleString()} ₽
                            </Typography>
                        </Paper>
                    </Grid>

                    {/* Расходы */}
                    <Grid size={{ xs: 12, md: 4 }}>
                        <Paper sx={{ ...glassStyle, borderTop: '4px solid #f44336' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                                <Typography variant="body2" sx={{ color: '#888', fontWeight: 600, textTransform: 'uppercase' }}>
                                    Общие расходы
                                </Typography>
                                <TrendingDownIcon sx={{ color: '#f44336' }} />
                            </Box>
                            <Typography variant="h4" sx={{ color: '#fff', fontWeight: 700 }}>
                                - {report.totalExpense.toLocaleString()} ₽
                            </Typography>
                        </Paper>
                    </Grid>

                    {/* Чистая прибыль */}
                    <Grid size={{ xs: 12, md: 4 }}>
                        <Paper sx={{ ...glassStyle, borderTop: `4px solid ${report.netProfit >= 0 ? '#61dafb' : '#f44336'}` }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                                <Typography variant="body2" sx={{ color: '#888', fontWeight: 600, textTransform: 'uppercase' }}>
                                    Чистая прибыль
                                </Typography>
                                <AccountBalanceWalletIcon sx={{ color: report.netProfit >= 0 ? '#61dafb' : '#f44336' }} />
                            </Box>
                            <Typography variant="h4" sx={{ color: report.netProfit >= 0 ? '#61dafb' : '#f44336', fontWeight: 700 }}>
                                {report.netProfit.toLocaleString()} ₽
                            </Typography>
                        </Paper>
                    </Grid>
                </Grid>
            )}
        </Box>
    );
};

export default FinancialSummary;