package demo;


import org.bouncycastle.util.Arrays;

import java.lang.annotation.Annotation;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;


/**
 * Created by tietang on 2015/4/13.
 */
public class ReflectUtils {


    public static Method getMethod(
            Class<?> clazz, String methodName, Class<?>... parameterTypes) {

        List<Method> methods = getMethods(clazz);
        for (Method method : methods) {

            if (method.getName().equals(methodName) && method.getParameterCount() == parameterTypes.length && Arrays.areEqual(
                    parameterTypes,
                    method.getParameterTypes())) {
                return method;
            }
        }
        return null;
    }


    public static List<Method> getMethods(
            Class<?> clazz, Class<? extends Annotation>... annotationFilters) {
        return getMethods(clazz, new ArrayList<>(), annotationFilters);
    }

    public static List<Method> getMethods(
            Class<?> clazz) {
        return getMethods(clazz, new ArrayList<>(), null);
    }

    public static List<Method> getMethods(
            Class<?> clazz, List<Method> methods, Class<? extends Annotation>... annotationFilters) {
        if (methods == null) {
            methods = new ArrayList<>();
        }
        Method[] declaredMethods = clazz.getDeclaredMethods();
        for (Method declaredMethod : declaredMethods) {
            boolean has = false;
            if (annotationFilters == null || annotationFilters.length == 0) {
                has = true;
            } else {
                for (Class<? extends Annotation> annotationFilter : annotationFilters) {
                    Annotation a = declaredMethod.getAnnotation(annotationFilter);
                    if (a != null) {
                        has = true;
                    }
                }
            }
            if (has) {
                methods.add(declaredMethod);
            }
        }

        Class<?> superClass = clazz.getSuperclass();
        if (superClass != null && superClass != Object.class) {
            getMethods(superClass, methods, annotationFilters);
        }
        return methods;
    }

    public static List<Field> getFields(
            Class<?> clazz) {
        return getFields(clazz, new ArrayList<>());
    }

    public static List<Field> getFields(
            Class<?> clazz, List<Field> fields) {
        if (fields == null) {
            fields = new ArrayList<>();
        }
        Field[] fls = clazz.getDeclaredFields();
        for (Field field : fls) {
            fields.add(field);
        }
        Class<?> superClass = clazz.getSuperclass();
        if (superClass != null && superClass != Object.class) {
            getFields(superClass, fields);
        }
        return fields;
    }

    public static Field getField(Class<?> clazz, String fieldName) throws Exception {
        if (clazz == null || clazz.getSimpleName().equals("Object")) {
            return null;
        }

        boolean hasField = existField(clazz, fieldName);
        if (!hasField) {
            return getSuperField(clazz, fieldName);
        }

        try {
            return clazz.getDeclaredField(fieldName);
        } catch (NoSuchFieldException e) {
            //            e.printStackTrace();
            //            Class<?> superClass = clazz.getSuperclass();
            //            return getField(superClass, fieldName, e);
            return getSuperField(clazz, fieldName);
        }
    }

    private static Field getSuperField(Class<?> childClass, String fieldName) throws Exception {
        Class<?> superClass = childClass.getSuperclass();
        return getField(superClass, fieldName);
    }

    private static boolean existField(Class<?> clazz, String fieldName) {
        Field[] fList = clazz.getDeclaredFields();
        for (Field f : fList) {
            if (f.getName().equals(fieldName)) {
                return true;
            }
        }
        return false;
    }


}
