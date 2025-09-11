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
@NamedEntityGraph(
    name = "Content.withCategory",
    attributeNodes = {
        @NamedAttributeNode(value = "category", subgraph = "Category.withParent")
    },
    subgraphs = @NamedSubgraph(
        name = "Category.withParent",
        attributeNodes = {
            @NamedAttributeNode("parent")
        }
    )
)
public class Content {

    @Id
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    private Category category;

    private String content;
}
