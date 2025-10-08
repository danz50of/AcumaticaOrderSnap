using System.Collections.Generic;
using System.Data.SqlClient;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace AcumaticaOrderSnap.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrderDeltaController : ControllerBase
    {
        private readonly IConfiguration _config;

        public OrderDeltaController(IConfiguration config)
        {
            _config = config;
        }

        [HttpGet]
        public IActionResult Get()
        {
            var metrics = new List<OrderMetrics>();
            string connStr = _config.GetConnectionString("OrderDeltaDB");

            try
            {
                using var conn = new SqlConnection(connStr);
                conn.Open();

                var cmd = new SqlCommand("SELECT * FROM vw_OrderMetrics ORDER BY SnapshotDate DESC", conn);
                var reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    metrics.Add(new OrderMetrics
                    {
                        SnapshotDate = reader["SnapshotDate"] != DBNull.Value ? Convert.ToDateTime(reader["SnapshotDate"]) : DateTime.MinValue,
                        TodayOpenOrderTotal = reader["TodayOpenOrderTotal"] != DBNull.Value ? Convert.ToDecimal(reader["TodayOpenOrderTotal"]) : 0,
                        YesterdayOpenOrderTotal = reader["YesterdayOpenOrderTotal"] != DBNull.Value ? Convert.ToDecimal(reader["YesterdayOpenOrderTotal"]) : 0,
                        DiffFromYesterday = reader["DiffFromYesterday"] != DBNull.Value ? Convert.ToDecimal(reader["DiffFromYesterday"]) : 0,
                        DeletedTotal = reader["DeletedTotal"] != DBNull.Value ? Convert.ToDecimal(reader["DeletedTotal"]) : 0,
                        DeletedCount = reader["DeletedCount"] != DBNull.Value ? Convert.ToInt32(reader["DeletedCount"]) : 0,
                        ModifiedTotal = reader["ModifiedTotal"] != DBNull.Value ? Convert.ToDecimal(reader["ModifiedTotal"]) : 0,
                        ModifiedCount = reader["ModifiedCount"] != DBNull.Value ? Convert.ToInt32(reader["ModifiedCount"]) : 0,
                        NewOrderTotal = reader["NewOrderTotal"] != DBNull.Value ? Convert.ToDecimal(reader["NewOrderTotal"]) : 0,
                        NewOrderCount = reader["NewOrderCount"] != DBNull.Value ? Convert.ToInt32(reader["NewOrderCount"]) : 0
                    });
                }

                return Ok(metrics);
            }
            catch (SqlException sqlEx)
            {
                return StatusCode(500, $"SQL Error: {sqlEx.Message}");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Unhandled Error: {ex.Message}");
            }
        }
    }
}