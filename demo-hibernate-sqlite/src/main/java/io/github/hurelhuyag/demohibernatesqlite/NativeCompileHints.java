package io.github.hurelhuyag.demohibernatesqlite;

import org.hibernate.boot.model.naming.ImplicitNamingStrategyComponentPathImpl;
import org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl;
import org.hibernate.community.dialect.SQLiteDialect;
import org.springframework.aot.hint.MemberCategory;
import org.springframework.aot.hint.RuntimeHints;
import org.springframework.aot.hint.RuntimeHintsRegistrar;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.ImportRuntimeHints;

@ImportRuntimeHints(MyHintRegistrar.class)
@Configuration
public class NativeCompileHints {
}

class MyHintRegistrar implements RuntimeHintsRegistrar {
    @Override
    public void registerHints(RuntimeHints hints, ClassLoader classLoader) {
        hints.resources()
                .registerPattern("init.sql")
                .registerPattern("schema.sql");

        hints.reflection()
                .registerType(ImplicitNamingStrategyComponentPathImpl.class, hint -> hint.withMembers(MemberCategory.INVOKE_DECLARED_CONSTRUCTORS))
                .registerType(PhysicalNamingStrategyStandardImpl.class, hint -> hint.withMembers(MemberCategory.INVOKE_DECLARED_CONSTRUCTORS))
                .registerType(SQLiteDialect.class, hint -> hint.withMembers(MemberCategory.INVOKE_DECLARED_CONSTRUCTORS))
        ;
    }
}
