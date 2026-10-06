package io.github.hurelhuyag.demohibernatesqlite.models;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "content")
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class Content {

    @Id
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    private Category category;

    private String content;
}
