import { useState, useEffect } from 'react'

function CategoryRatio() {
    const [report, setReport] = useState(null);
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');

    const fetchData = () => {
        const params = new URLSearchParams();
        if (startDate) params.append('startDate', startDate);
        if (endDate) params.append('endDate', endDate);

        fetch(`http://localhost:5000/api/Reports/category-ratio?${params.toString()}`)
            .then(response => response.json())
            .then(result => setReport(result))
            .catch(error => console.error('Ошибка:', error));
    };

    // Вызываем при первой загрузке (без фильтров)
    useEffect(() => {
        fetchData();
    }, []);

    return (
        <div>
            <h2>14. Отношение отдыхающих к шоп-турам</h2>

            <div style={{ marginBottom: '20px', display: 'flex', gap: '10px' }}>
                <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} />
                <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} />
                <button onClick={fetchData}>Обновить</button>
            </div>

            {report && (
                <div style={{ padding: '20px', backgroundColor: '#2d2d2d', borderRadius: '5px' }}>
                    <p><strong>Всего туристов (с учетом фильтра):</strong> {report.totalTourists}</p>
                    <hr style={{ borderColor: '#444' }} />
                    <div style={{ display: 'flex', gap: '50px', marginTop: '20px' }}>
                        <div>
                            <h3 style={{ color: '#4caf50', margin: '0 0 10px 0' }}>Отдых</h3>
                            <p style={{ margin: 0 }}>Количество: {report.holidayCount}</p>
                            <h1 style={{ margin: '10px 0 0 0' }}>{report.holidayPercentage}%</h1>
                        </div>
                        <div>
                            <h3 style={{ color: '#ff9800', margin: '0 0 10px 0' }}>Шоп-тур</h3>
                            <p style={{ margin: 0 }}>Количество: {report.shopTourCount}</p>
                            <h1 style={{ margin: '10px 0 0 0' }}>{report.shopTourPercentage}%</h1>
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}

export default CategoryRatio;