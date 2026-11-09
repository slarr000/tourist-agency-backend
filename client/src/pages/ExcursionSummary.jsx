import { useState, useEffect } from 'react'

function ExcursionSummary() {
    const [data, setData] = useState([]);

    useEffect(() => {
        fetch('http://localhost:5000/api/Reports/excursions-summary')
            .then(response => response.json())
            .then(result => setData(result))
            .catch(error => console.error('Ошибка:', error));
    }, []);

    return (
        <div>
            <h2>7. Самые популярные экскурсии</h2>
            <table border="1" cellPadding="10" style={{ width: '100%' }}>
                <thead>
                    <tr>
                        <th>Название экскурсии / Место</th>
                        <th>Количество бронирований</th>
                    </tr>
                </thead>
                <tbody>
                    {data.map((item, index) => (
                        <tr key={index}>
                            <td>{item.visitPlace}</td>
                            <td>{item.totalTourists}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    )
}

export default ExcursionSummary;