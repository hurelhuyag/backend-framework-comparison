package io.github.hurelhuyag.demohibernatesqlite.models;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Entity
@Table(name = "category")
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@NamedEntityGraph(
    name = "Category.withParent",
    attributeNodes = {
        @NamedAttributeNode("parent")
    }
)
public class Category {

    @Id
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    private Category parent;

    private String name;

    @OneToMany(mappedBy = "parent")
    @OrderBy("id")
    private List<Category> children;

    @OneToMany(mappedBy = "category")
    private List<Content> contents;
}
