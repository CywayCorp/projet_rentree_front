import { createSlice } from '@reduxjs/toolkit'
import axios from "axios";

export const tagsSlice = createSlice({
    name: 'tags',
    initialState: {
        value: [],
        status: 'idle',
        error: null,
    },
    reducers: {
        // ...
    },
    extraReducers: (builder) => {
        builder
            .addCase(loadTags.pending, (state) => {
                state.status = 'loading';
            })
            .addCase(loadTags.fulfilled, (state, action) => {
                state.status = 'succeeded';
                state.value = action.payload;
            })
            .addCase(loadTags.rejected, (state, action) => {
                state.status = 'failed';
            });
    },
});

// ...


import { createAsyncThunk } from '@reduxjs/toolkit';


// Définissez une fonction asynchrone pour charger les données
export const loadTags = createAsyncThunk(
    'tags/load',
    async (_, thunkAPI) => {
        try {
            const response = await axios.get('http://localhost:8080/api/dishes/tags');
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
);

// ...

// Action creators are generated for each case reducer function
export const { load } = tagsSlice.actions;

export default tagsSlice.reducer