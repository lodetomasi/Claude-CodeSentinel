package com.example;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.http.HttpServletRequest;

/**
 * User controller with multiple security and performance issues
 * FOR TESTING PURPOSES ONLY - DO NOT USE IN PRODUCTION
 */
public class UserController {

    // ISSUE: Hardcoded database credentials (Security - CRITICAL)
    private static final String DB_URL = "jdbc:mysql://localhost:3306/users";
    private static final String DB_USER = "admin";
    private static final String DB_PASSWORD = "password123";

    // ISSUE: No connection pooling (Performance - HIGH)
    private Connection getConnection() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    }

    // ISSUE: SQL Injection vulnerability (Security - CRITICAL)
    public User getUserByEmail(String email) throws SQLException {
        Connection conn = getConnection();
        // BAD: String concatenation in SQL query
        String query = "SELECT * FROM users WHERE email = '" + email + "'";
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(query);

        User user = null;
        if (rs.next()) {
            user = new User();
            user.setId(rs.getLong("id"));
            user.setEmail(rs.getString("email"));
            user.setPassword(rs.getString("password")); // ISSUE: Returning password
        }

        // ISSUE: Resource leak - connection not closed properly (Concurrency - HIGH)
        conn.close();
        return user;
    }

    // ISSUE: N+1 Query Problem (Performance - CRITICAL)
    public List<UserWithOrders> getAllUsersWithOrders() throws SQLException {
        List<UserWithOrders> result = new ArrayList<>();
        Connection conn = getConnection();

        // First query: get all users
        String query = "SELECT * FROM users";
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(query);

        while (rs.next()) {
            UserWithOrders userWithOrders = new UserWithOrders();
            userWithOrders.setUserId(rs.getLong("id"));
            userWithOrders.setEmail(rs.getString("email"));

            // ISSUE: N+1 - One query per user to get orders
            String orderQuery = "SELECT * FROM orders WHERE user_id = " + rs.getLong("id");
            Statement orderStmt = conn.createStatement();
            ResultSet orderRs = orderStmt.executeQuery(orderQuery);

            List<Order> orders = new ArrayList<>();
            while (orderRs.next()) {
                Order order = new Order();
                order.setId(orderRs.getLong("id"));
                order.setTotal(orderRs.getDouble("total"));
                orders.add(order);
            }
            userWithOrders.setOrders(orders);
            result.add(userWithOrders);
        }

        conn.close();
        return result;
    }

    // ISSUE: No input validation (API Design - HIGH)
    // ISSUE: No authentication check (Security - CRITICAL)
    public void updateUser(HttpServletRequest request) throws SQLException {
        String userId = request.getParameter("id");
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        // ISSUE: No transaction (Data Integrity - HIGH)
        Connection conn = getConnection();

        // ISSUE: SQL Injection again
        String updateQuery = "UPDATE users SET email = '" + email +
                           "', password = '" + password +
                           "' WHERE id = " + userId;

        Statement stmt = conn.createStatement();
        stmt.executeUpdate(updateQuery);

        // ISSUE: No logging (Observability - MEDIUM)
        // Should log: who updated what and when

        conn.close();
    }

    // ISSUE: Synchronous blocking operation (Performance - MEDIUM)
    // ISSUE: No timeout (Resilience - HIGH)
    public void sendEmailToAllUsers() throws SQLException {
        Connection conn = getConnection();
        String query = "SELECT email FROM users";
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(query);

        while (rs.next()) {
            String email = rs.getString("email");
            // Blocking call without timeout
            EmailService.sendEmail(email, "Newsletter", "Content here");
        }

        conn.close();
    }

    // ISSUE: Poor error handling (Observability - HIGH)
    public User getUser(Long id) {
        try {
            Connection conn = getConnection();
            String query = "SELECT * FROM users WHERE id = " + id;
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery(query);

            if (rs.next()) {
                User user = new User();
                user.setId(rs.getLong("id"));
                return user;
            }
        } catch (Exception e) {
            // ISSUE: Silent failure - swallowing exception
            // ISSUE: No logging of error
        }
        return null;
    }

    // Inner classes for example
    static class User {
        private Long id;
        private String email;
        private String password;

        // Getters and setters
        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    static class Order {
        private Long id;
        private Double total;

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public Double getTotal() { return total; }
        public void setTotal(Double total) { this.total = total; }
    }

    static class UserWithOrders {
        private Long userId;
        private String email;
        private List<Order> orders;

        public Long getUserId() { return userId; }
        public void setUserId(Long userId) { this.userId = userId; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public List<Order> getOrders() { return orders; }
        public void setOrders(List<Order> orders) { this.orders = orders; }
    }

    static class EmailService {
        public static void sendEmail(String to, String subject, String body) {
            // Simulate email sending
            try {
                Thread.sleep(100); // Simulate network delay
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }
}