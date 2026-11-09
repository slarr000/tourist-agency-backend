import { useState, useEffect } from 'react';
import {
    Box, Typography, Paper, Table, TableBody, TableCell,
    TableContainer, TableHead, TableRow, Button, CircularProgress, Chip
} from '@mui/material';
import DownloadIcon from '@mui/icons-material/Download';
import SecurityIcon from '@mui/icons-material/Security';

function CustomsList() {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);

    // Имитация загрузки данных. Позже заменим на реальный fetch к нашему C# API
    useEffect(() => {
        const fetchData = async () => {
            try {
                // const response = await fetch('https://localhost:7062/api/Reports/CustomsList');
                // const result = await response.json();

                // Временная заглушка для красоты
                setTimeout(() => {
                    setData([
                        { id: 101, surname: 'Иванов', name: 'Иван', passport: 'AB1234567', baggageWeight: 15.5, status: 'Clear' },
                        { id: 102, surname: 'Петрова', name: 'Анна', passport: 'CD9876543', baggageWeight: 24.0, status: 'Warning' },
                        { id: 103, surname: 'Сидоров', name: 'Петр', passport: 'EF4567890', baggageWeight: 10.0, status: 'Clear' },
                        { id: 104, surname: 'Дыгданов', name: 'Ярослав', passport: 'BY7777777', baggageWeight: 18.2, status: 'Clear' },
                    ]);
                    setLoading(false);
                }, 800); // 800мс искусственной задержки для показа красивого лоадера
            } catch (error) {
                console.error("Ошибка загрузки", error);
                setLoading(false);
            }
        };
        fetchData();
    }, []);

    return (
        <Box sx={{ maxWidth: '1200px', margin: '0 auto', animation: 'fadeIn 0.5s ease-in-out' }}>

            {/* ЗАГОЛОВОК И КНОПКИ */}
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', mb: 4 }}>
                <Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1 }}>
                        <Box sx={{ p: 1, borderRadius: '10px', backgroundColor: 'rgba(97, 218, 251, 0.1)', border: '1px solid rgba(97, 218, 251, 0.2)' }}>
                            <SecurityIcon sx={{ color: '#61dafb', fontSize: 24, display: 'block' }} />
                        </Box>
                        <Typography variant="h4" sx={{ fontWeight: 800, color: '#fff', letterSpacing: '-0.5px' }}>
                            Список для таможни
                        </Typography>
                    </Box>
                    <Typography variant="body1" sx={{ color: '#888', ml: 7 }}>
                        Контроль пассажиров и проверка багажа при пересечении границы
                    </Typography>
                </Box>
                <Button
                    variant="outlined"
                    startIcon={<DownloadIcon />}
                    sx={{
                        color: '#61dafb',
                        borderColor: 'rgba(97, 218, 251, 0.3)',
                        borderRadius: '12px',
                        textTransform: 'none',
                        fontWeight: 600,
                        px: 3,
                        '&:hover': { borderColor: '#61dafb', backgroundColor: 'rgba(97, 218, 251, 0.1)' }
                    }}
                >
                    Экспорт PDF
                </Button>
            </Box>

            {/* СТЕКЛЯННАЯ ТАБЛИЦА */}
            <TableContainer
                component={Paper}
                sx={{
                    backgroundColor: 'rgba(18, 18, 18, 0.4)', // Полупрозрачный фон
                    backdropFilter: 'blur(12px)', // Эффект матового стекла
                    borderRadius: '16px',
                    border: '1px solid rgba(255, 255, 255, 0.05)',
                    boxShadow: '0 8px 32px rgba(0,0,0,0.2)',
                    backgroundImage: 'none'
                }}
            >
                <Table>
                    <TableHead sx={{ backgroundColor: 'rgba(255, 255, 255, 0.02)' }}>
                        <TableRow>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '1px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>ID рейса</TableCell>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '1px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Пассажир</TableCell>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '1px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Паспорт</TableCell>
                            <TableCell align="center" sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '1px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Вес багажа</TableCell>
                            <TableCell align="center" sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '1px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Статус</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center" sx={{ py: 10, borderBottom: 'none' }}>
                                    <CircularProgress sx={{ color: '#61dafb' }} />
                                </TableCell>
                            </TableRow>
                        ) : data.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center" sx={{ py: 6, color: '#666', borderBottom: 'none' }}>
                                    Нет данных для отображения
                                </TableCell>
                            </TableRow>
                        ) : (
                            data.map((row) => (
                                <TableRow
                                    key={row.id}
                                    sx={{
                                        transition: 'all 0.2s',
                                        '&:hover': { backgroundColor: 'rgba(255, 255, 255, 0.03)' },
                                        '& td': { borderBottom: '1px solid rgba(255,255,255,0.03)', color: '#e0e0e0', py: 2.5 },
                                        '&:last-child td': { borderBottom: 'none' }
                                    }}
                                >
                                    <TableCell sx={{ color: '#666 !important', fontWeight: 600 }}>#{row.id}</TableCell>
                                    <TableCell>
                                        <Typography variant="body2" sx={{ fontWeight: 600, color: '#fff', letterSpacing: '0.5px' }}>
                                            {row.surname} {row.name}
                                        </Typography>
                                    </TableCell>
                                    <TableCell sx={{ fontFamily: 'monospace', color: '#aaa', fontSize: '14px', letterSpacing: '1px' }}>
                                        {row.passport}
                                    </TableCell>
                                    <TableCell align="center">
                                        {/* Если перевес (больше 20кг) - красим в оранжевый */}
                                        <Typography variant="body2" sx={{ fontWeight: 600, color: row.baggageWeight > 20 ? '#ffb74d' : '#fff' }}>
                                            {row.baggageWeight} кг
                                        </Typography>
                                    </TableCell>
                                    <TableCell align="center">
                                        {row.status === 'Warning' ? (
                                            <Chip label="Досмотр" size="small" sx={{ backgroundColor: 'rgba(255, 152, 0, 0.1)', color: '#ff9800', fontWeight: 700, borderRadius: '6px', border: '1px solid rgba(255, 152, 0, 0.2)' }} />
                                        ) : (
                                            <Chip label="Допущен" size="small" sx={{ backgroundColor: 'rgba(76, 175, 80, 0.1)', color: '#4caf50', fontWeight: 700, borderRadius: '6px', border: '1px solid rgba(76, 175, 80, 0.2)' }} />
                                        )}
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
}

export default CustomsList;