package com.gler.devops.model.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder(toBuilder = true)
public class OrderResponse {
    private String orderId;
    private String customerId;
    private LocalDateTime orderDate;
    private BigDecimal totalAmount;
    private String status;
    private String paymentMethod;
    private String shippingAddress;
}
