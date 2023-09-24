import { StatusBar } from 'expo-status-bar';
import {Button, Picker, StyleSheet, Text, View} from 'react-native';
import Product from '../components/Product';
import { Image } from 'react-native-web';
import { CheckBox } from '@rneui/base';
import {Select} from "evergreen-ui";
import React, {useEffect, useState} from "react";
import BottomNavigationBar from "../components/BottomNavigationBar";
import {useApplicationContext} from "../components/AuthContext";
import {useDispatch, useSelector} from "react-redux";
import {addDishesToBasket} from "../features/dishes/Basket";
import {loadDish} from "../features/dishes/Dish";

const styles = StyleSheet.create({
    container: {
        backgroundColor: 'white',
        height: '100%',
    },
    fullwidthImage: {
        width: '100%',
        aspectRatio: 1,
    },
    textContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 10,
        justifyContent: 'center'
    },
    title: {
        fontSize: 20,
        fontWeight: 'bold',
        marginRight: 10,
    },
    price: {
        fontSize: 18,
        color: 'green',
    },
    description: {
        fontSize: 16,
        marginBottom: 10,
    },
    allergenes: {
        fontSize: 16,
    },
    divider: {
        width: 1,
        height: '100%',
        marginHorizontal: 10,
    },
    columnContainer: {
        flexDirection: 'row',
        justifyContent: 'space-between',
    },
    halfContainer: {
        flex: 1,
    },
    bottomNavContainer: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
    },
});

export default function ObjectDetail({ route, navigation }) {
    const { id } = route.params;

    // Ajoutez un state pour gérer la quantité de plats
    const [quantity, setQuantity] = useState(1);

    const dish = useSelector(state => state.dish.value);

    const dispatch = useDispatch();

    useEffect(() => {
        console.log("useEffect")
        dispatch(loadDish(id));
    }  , []);

    return (
        <View style={styles.container}>
            <View style={styles.imageContainer}>
                <Image
                    style={styles.fullwidthImage}
                    source={{
                        uri: dish?.image,
                    }}
                />
            </View>
            <View style={styles.textContainer}>
                <Text style={styles.title}>{dish?.title}</Text>
                <Text style={styles.price}>{dish?.price} €</Text>
                <Picker // Utilisez le Picker pour la quantité
                    selectedValue={quantity}
                    onValueChange={(itemValue, itemIndex) => setQuantity(itemValue)}
                >
                    <Picker.Item label="1" value={1} />
                    <Picker.Item label="2" value={2} />
                    <Picker.Item label="3" value={3} />
                    <Picker.Item label="4" value={4} />
                    <Picker.Item label="5" value={5} />
                    <Picker.Item label="6" value={6} />
                    <Picker.Item label="7" value={7} />
                </Picker>
                <Button title={'ajouter au panier'} onPress={() => dispatch(addDishesToBasket({ dishId: id, quantity: quantity }))} />
            </View>

            <View style={styles.columnContainer}>
                <View style={styles.halfContainer}>
                    <Text style={styles.title}>Description</Text>
                    <Text style={styles.description}>{dish?.description}</Text>
                </View>
                <View style={styles.divider}></View>
                <View style={styles.halfContainer}>
                    <Text style={styles.title}>Allergènes</Text>
                    <Text style={styles.allergenes}>{dish?.alergens}</Text>
                </View>
            </View>
            <View style={styles.bottomNavContainer}>
                <BottomNavigationBar navigation={navigation}/>
            </View>

        </View>
    );
}