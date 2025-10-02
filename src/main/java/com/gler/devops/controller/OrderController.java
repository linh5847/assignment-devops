package com.gler.devops.controller;

import com.gler.devops.model.response.OrderResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/v1/order")
public class OrderController {

    @GetMapping
    public ResponseEntity<List<OrderResponse>> getOrderList(){
        List<OrderResponse> orderResponseList =
                List.of(
                        OrderResponse.builder().orderId("ORD-1001").customerId("CUST-001").orderDate(LocalDateTime.now().minusDays(5)).totalAmount(new BigDecimal("120.50")).status("PENDING").paymentMethod("CREDIT_CARD").shippingAddress("123 Main St, New York, NY").build(),
                        OrderResponse.builder().orderId("ORD-1002").customerId("CUST-002").orderDate(LocalDateTime.now().minusDays(4)).totalAmount(new BigDecimal("250.00")).status("PROCESSING").paymentMethod("PAYPAL").shippingAddress("456 Oak Ave, Los Angeles, CA").build(),
                        OrderResponse.builder().orderId("ORD-1003").customerId("CUST-003").orderDate(LocalDateTime.now().minusDays(3)).totalAmount(new BigDecimal("75.99")).status("SHIPPED").paymentMethod("DEBIT_CARD").shippingAddress("789 Pine Rd, Chicago, IL").build(),
                        OrderResponse.builder().orderId("ORD-1004").customerId("CUST-004").orderDate(LocalDateTime.now().minusDays(2)).totalAmount(new BigDecimal("340.75")).status("DELIVERED").paymentMethod("CASH_ON_DELIVERY").shippingAddress("12 Elm St, Houston, TX").build(),
                        OrderResponse.builder().orderId("ORD-1005").customerId("CUST-005").orderDate(LocalDateTime.now().minusDays(1)).totalAmount(new BigDecimal("199.99")).status("CANCELLED").paymentMethod("CREDIT_CARD").shippingAddress("98 Maple Dr, Seattle, WA").build(),
                        OrderResponse.builder().orderId("ORD-1006").customerId("CUST-006").orderDate(LocalDateTime.now().minusDays(7)).totalAmount(new BigDecimal("450.00")).status("PENDING").paymentMethod("APPLE_PAY").shippingAddress("77 River Rd, Miami, FL").build(),
                        OrderResponse.builder().orderId("ORD-1007").customerId("CUST-007").orderDate(LocalDateTime.now().minusDays(6)).totalAmount(new BigDecimal("89.49")).status("DELIVERED").paymentMethod("GOOGLE_PAY").shippingAddress("22 Sunset Blvd, San Diego, CA").build(),
                        OrderResponse.builder().orderId("ORD-1008").customerId("CUST-008").orderDate(LocalDateTime.now().minusHours(30)).totalAmount(new BigDecimal("560.00")).status("PROCESSING").paymentMethod("CREDIT_CARD").shippingAddress("145 Hilltop Ln, Austin, TX").build(),
                        OrderResponse.builder().orderId("ORD-1009").customerId("CUST-009").orderDate(LocalDateTime.now().minusHours(20)).totalAmount(new BigDecimal("310.10")).status("SHIPPED").paymentMethod("PAYPAL").shippingAddress("88 Forest Path, Denver, CO").build(),
                        OrderResponse.builder().orderId("ORD-1010").customerId("CUST-010").orderDate(LocalDateTime.now().minusHours(10)).totalAmount(new BigDecimal("49.99")).status("DELIVERED").paymentMethod("CREDIT_CARD").shippingAddress("654 Market St, San Francisco, CA").build(),
                        OrderResponse.builder().orderId("ORD-1011").customerId("CUST-011").orderDate(LocalDateTime.now().minusHours(8)).totalAmount(new BigDecimal("720.00")).status("PENDING").paymentMethod("BANK_TRANSFER").shippingAddress("432 Park Ave, New York, NY").build(),
                        OrderResponse.builder().orderId("ORD-1012").customerId("CUST-012").orderDate(LocalDateTime.now().minusHours(6)).totalAmount(new BigDecimal("135.75")).status("CANCELLED").paymentMethod("CREDIT_CARD").shippingAddress("99 Ocean Dr, Honolulu, HI").build(),
                        OrderResponse.builder().orderId("ORD-1013").customerId("CUST-013").orderDate(LocalDateTime.now().minusHours(4)).totalAmount(new BigDecimal("480.25")).status("PROCESSING").paymentMethod("PAYPAL").shippingAddress("12 Mountain Rd, Phoenix, AZ").build(),
                        OrderResponse.builder().orderId("ORD-1014").customerId("CUST-014").orderDate(LocalDateTime.now().minusHours(2)).totalAmount(new BigDecimal("66.66")).status("DELIVERED").paymentMethod("DEBIT_CARD").shippingAddress("55 Lake View, Orlando, FL").build(),
                        OrderResponse.builder().orderId("ORD-1015").customerId("CUST-015").orderDate(LocalDateTime.now()).totalAmount(new BigDecimal("890.00")).status("SHIPPED").paymentMethod("CREDIT_CARD").shippingAddress("321 Sunset Dr, Dallas, TX").build()
        );
        return ResponseEntity.ok(orderResponseList);
    }

}
